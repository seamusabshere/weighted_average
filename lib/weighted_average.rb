require 'active_record'

module WeightedAverage
  # Returns a number.
  def weighted_average(*args)
    connection.select_value(weighted_average_relation(*args).to_sql, 'weighted_average').to_f
  end

  # Returns the ARel relation for a weighted average query.
  def weighted_average_relation(column_names, options = {})
    raise ArgumentError, "Only use array form if the weighting column in the foreign table is not called 'weighting'" if options[:weighted_by].is_a?(Array) and options[:weighted_by].length != 2
    raise ArgumentError, "No nil values in weighted_by, please" if Array.wrap(options[:weighted_by]).any?(&:nil?)
  
    # aircraft['seats'] or (aircraft['seats'] + aircraft['payload'])
    columns = Array.wrap(column_names).map { |column_name| arel_table[column_name.to_s] }

    # :airline_aircraft_seat_class
    association = if options[:weighted_by].present?
      options[:weighted_by].is_a?(Array) ? reflect_on_association(options[:weighted_by].first.to_sym) : reflect_on_association(options[:weighted_by].to_sym)
    end
  
    # AirlineAircraftSeatClass
    association_class = association.klass if association
        
    # AirlineAircraftSeatClass.arel_table
    foreign_arel_table = association_class.arel_table if association_class
  
    # 'weighting'
    weighted_by_column = if association_class and options[:weighted_by].is_a?(Array)
      options[:weighted_by].last.to_s
    elsif !association_class and (options[:weighted_by].is_a?(String) or options[:weighted_by].is_a?(Symbol))
      options[:weighted_by].to_s
    else
      'weighting'
    end
  
    # [foreign_]arel_table['weighting']
    weighted_by = if foreign_arel_table
      foreign_arel_table[weighted_by_column]
    else
      arel_table[weighted_by_column]
    end

    disaggregate_by = if options[:disaggregate_by].present?
      raise ArgumentError, "Disaggregating by a foreign table isn't supported right now" if options[:disaggregate_by].is_a?(Array)
      arel_table[options[:disaggregate_by].to_s]
    end

    relation = select("(SUM((#{columns.map { |column| column.to_sql }.join(' + ')}) #{"/ #{disaggregate_by.to_sql} " if disaggregate_by}* #{weighted_by.to_sql}) / SUM(#{weighted_by.to_sql})) AS weighted_average")
    columns.each do |column|
      relation = relation.where("#{column.to_sql} IS NOT NULL")
    end
    # FIXME this will break on through relationships, where it has to be :aircraft => :aircraft_class
    relation = relation.joins(association.name) if association_class
    relation
  end
end

ActiveRecord::Associations::AssociationCollection.class_eval do
  def self.weighted_average(*args) # :nodoc:
    scoped.weighted_average(*args)
  end
  
  def self.weighted_average_relation(*args) # :nodoc:
    scoped.weighted_average_relation(*args)
  end
end
ActiveRecord::Base.class_eval do
  def self.weighted_average(*args) # :nodoc:
    scoped.weighted_average(*args)
  end
  
  def self.weighted_average_relation(*args) # :nodoc:
    scoped.weighted_average_relation(*args)
  end
end

ActiveRecord::Relation.send :include, WeightedAverage
