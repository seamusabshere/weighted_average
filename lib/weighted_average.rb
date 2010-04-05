require 'active_record'

module ActiveRecord
  module WeightedAverage
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def update_all_weighted_averages(column_name, weighting_options = {}, options = {})
        sql = construct_update_all_weighted_averages_sql(column_name, weighting_options, options)
        update_all("#{column_name} = NULL")
        connection.execute(sql)
      end
      
      def weighted_average(column_name, weighting_options = {}, options = {})
        sql = construct_weighted_average_sql(column_name, weighting_options, options)
        value = connection.select_value(sql)
        value.blank? ? nil : value.to_f
      end
      
      protected
      
      def construct_update_all_weighted_averages_sql(column_name, weighting_options = {}, options = {})
        quoted_table_name = connection.quote_table_name(table_name)
        association = reflect_on_association(weighting_options[:association])
        
        if association.options[:through]
          options[:include] = Array.wrap(options[:include]) + [ association.through_reflection.name ]
          # flight_aircraft.flight_aircraft_class_id = flight_aircraft_classes.id AND flight_airline_aircraft_seat_class.flight_aircraft_id = flight_aircraft.id
          options[:conditions] = "#{association.through_reflection.quoted_table_name}.#{association.through_reflection.primary_key_name} = #{quoted_table_name}.id AND #{association.quoted_table_name}.#{association.source_reflection.primary_key_name} = #{association.through_reflection.quoted_table_name}.id"
        else
          # flight_aircraft.flight_aircraft_class_id = flight_aircraft_classes.id
          options[:conditions] = "#{association.quoted_table_name}.#{association.primary_key_name} = #{quoted_table_name}.id"
        end
        
        subquery = association.klass.construct_weighted_average_sql(column_name, weighting_options.slice(:by, :disaggregator), options)
        
        sql = "UPDATE #{quoted_table_name} SET #{quoted_table_name}.#{column_name} = (#{subquery})"
        
        sql.strip
      end
      
      # heavily modified construct_calculation_sql from calculations.rb
      # should be updated to match once we've gone to 2.3
      def construct_weighted_average_sql(columns, weighting_options = {}, options = {})
        options = options.symbolize_keys
        column_name = case columns
        when Array
           '(' + columns.map { |i| "#{connection.quote_table_name(table_name)}.#{i}" }.join(' + ') + ')'
        when String, Symbol
          "#{connection.quote_table_name(table_name)}.#{columns}"
        end
        
        if weighting_options[:association]
          association = reflect_on_association(weighting_options[:association])
          options[:include] = Array.wrap(options[:include]) + [ weighting_options[:association] ]
        end
        
        weighting_column_name = add_weighting_table_name(weighting_options[:by] || 'weighting', association)
        disaggregator_column_name = add_weighting_table_name(weighting_options[:disaggregator], association) if weighting_options[:disaggregator]

        if weighting_options[:disaggregator]
          select = "SUM(#{column_name} / #{disaggregator_column_name} * #{weighting_column_name}) / SUM(#{weighting_column_name})"
        else
          select = "SUM(#{column_name} * #{weighting_column_name}) / SUM(#{weighting_column_name})"
        end

        columns_conditions = case columns
        when Array
          columns.map { |i| "#{connection.quote_table_name(table_name)}.#{i} IS NOT NULL" }.join(' AND ')
        when String, Symbol
          "#{column_name} IS NOT NULL"
        end
        options[:conditions] = merge_conditions(options[:conditions], columns_conditions)
        
        scope           = scope(:find)
        merged_includes = merge_includes(scope ? scope[:include] : [], options[:include])
        aggregate_alias = 'weighted_average'
        
        sql = "SELECT (#{select}) AS #{aggregate_alias}"
        
        sql << ", #{options[:group_field]} AS #{options[:group_alias]}" if options[:group]
        if options[:from]
          sql << " FROM #{options[:from]} "
        else
          sql << " FROM #{connection.quote_table_name(table_name)} "
        end
        
        joins = ""
        add_joins!(joins, options[:joins], scope)

        if merged_includes.any?
          join_dependency = ActiveRecord::Associations::ClassMethods::JoinDependency.new(self, merged_includes, joins)
          sql << join_dependency.join_associations.collect{|join| join.association_join }.join
        end

        sql << joins unless joins.blank?
        
        add_conditions!(sql, options[:conditions], scope)
        add_limited_ids_condition!(sql, options, join_dependency) if join_dependency && !using_limitable_reflections?(join_dependency.reflections) && ((scope && scope[:limit]) || options[:limit])

        if options[:group]
          sql << " GROUP BY #{options[:group_field]} "
        end

        if options[:group] && options[:having]
          having = sanitize_sql_for_conditions(options[:having])
          sql << " HAVING #{options[:having]} "
        end

        sql << " ORDER BY #{options[:order]} "       if options[:order]
        add_limit!(sql, options, scope)
        sql
      end
      
      def add_weighting_table_name(column_name, association)
        if association and not /#{association.table_name}.*\./.match(column_name.to_s)
          "#{connection.quote_table_name(association.table_name)}.#{column_name}"
        elsif not /#{table_name}.*\./.match(column_name.to_s)
          "#{connection.quote_table_name(table_name)}.#{column_name}"
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include ActiveRecord::WeightedAverage
end