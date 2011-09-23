require 'active_support/core_ext'
require 'active_record'
require "weighted_average/version"

module WeightedAverage
  # Returns a number.
  def weighted_average(*args)
    connection.select_value(weighted_average_relation(*args).to_sql, 'weighted_average').to_f
  end

  # Returns the ARel relation for a weighted average query.
  def weighted_average_relation(data_column_names, options = {})
    raise ::ArgumentError, "Only use array form if the weighting column in the foreign table is not called 'weighting'" if options[:weighted_by].is_a?(::Array) and options[:weighted_by].length != 2
    raise ::ArgumentError, "No nil values in weighted_by, please" if ::Array.wrap(options[:weighted_by]).any?(&:nil?)
  
    # :airline_aircraft_seat_class
    association = if options[:weighted_by].present?
      options[:weighted_by].is_a?(::Array) ? reflect_on_association(options[:weighted_by].first.to_sym) : reflect_on_association(options[:weighted_by].to_sym)
    end
  
    # AirlineAircraftSeatClass
    association_class = association.klass if association
    
    # `airline_aircraft_seat_classes`
    weighted_by_table_name = if association_class
      association_class.quoted_table_name
    else
      quoted_table_name
    end
      
    # `airline_aircraft_seat_classes`.`weighting`
    weighted_by_column_name = if association_class and options[:weighted_by].is_a?(::Array)
      options[:weighted_by].last.to_s
    elsif !association_class and (options[:weighted_by].is_a?(::String) or options[:weighted_by].is_a?(::Symbol))
      options[:weighted_by].to_s
    else
      'weighting'
    end
    weighted_by_column_name = [ weighted_by_table_name, connection.quote_column_name(weighted_by_column_name) ].join '.'
    
    # `aircraft`.`passengers`
    disaggregate_by_column_name = if options[:disaggregate_by]
      [ quoted_table_name, connection.quote_column_name(options[:disaggregate_by]) ].join '.'
    end

    # [ `aircraft`.`foo`, `aircraft`.`baz` ]
    data_column_names = ::Array.wrap(data_column_names).map do |data_column_name|
      [ quoted_table_name, connection.quote_column_name(data_column_name) ].join '.'
    end

    relation = select("(SUM((#{data_column_names.join(' + ')}) #{"/ #{disaggregate_by_column_name} " if disaggregate_by_column_name}* #{weighted_by_column_name}) / SUM(#{weighted_by_column_name})) AS weighted_average")
    data_column_names.each do |data_column_name|
      relation = relation.where("#{data_column_name} IS NOT NULL")
    end
    # FIXME this will break on through relationships, where it has to be :aircraft => :aircraft_class
    relation = relation.joins(association.name) if association_class
    relation
  end
end

(defined?(::ActiveRecord::Associations::CollectionProxy) ? ::ActiveRecord::Associations::CollectionProxy : ::ActiveRecord::Associations::AssociationCollection).class_eval do
  def self.weighted_average(*args) # :nodoc:
    scoped.weighted_average(*args)
  end
  
  def self.weighted_average_relation(*args) # :nodoc:
    scoped.weighted_average_relation(*args)
  end
end
::ActiveRecord::Base.class_eval do
  def self.weighted_average(*args) # :nodoc:
    scoped.weighted_average(*args)
  end
  
  def self.weighted_average_relation(*args) # :nodoc:
    scoped.weighted_average_relation(*args)
  end
end

::ActiveRecord::Relation.send :include, ::WeightedAverage
