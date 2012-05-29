module WeightedAverage
  module ActiveRecordRelationInstanceMethods
    # Returns a number.
    def weighted_average(*args)
      weighted_average = connection.select_value weighted_average_relation(*args).to_sql
      weighted_average.nil? ? nil : weighted_average.to_f
    end

    # :hfc_emission_factor => lambda { fallback_type_years.weighted_average(:hfc_emission_factor, :weighted_by => [:type_fuel_years, :total_travel]) },
    # Returns the ARel relation for a weighted average query.
    def weighted_average_relation(data_column_names, options = {})
      if weighted_by_option = options[:weighted_by]
        case weighted_by_option
        when Array
          # :weighted_by specifies a custom column on an association table (least common)
          unless association = reflect_on_association(weighted_by_option.first)
            raise ArgumentError, "#{name} does not have association #{weighted_by_option.first.inspect}"
          end
          weighted_by_column = association.klass.arel_table[weighted_by_option.last]
        when Symbol, String
          if association = reflect_on_association(weighted_by_option)
            # :weighted_by specifies an association table with a column named "weighting"
            weighted_by_column = association.klass.arel_table[DEFAULT_WEIGHTED_BY_COLUMN_NAME]
          else
            # :weighted_by specifies a custom column on the same table
            weighted_by_column = arel_table[weighted_by_option]
          end
        end
        if association
          joins(association.name).arel.weighted_average_relation data_column_names, options.merge(:weighted_by => weighted_by_column)
        else
          arel.weighted_average_relation data_column_names, options.merge(:weighted_by => weighted_by_column)
        end
      else
        arel.weighted_average_relation data_column_names, options
      end
    end

  end
end
