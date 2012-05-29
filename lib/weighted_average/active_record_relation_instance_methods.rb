module WeightedAverage
  module ActiveRecordRelationInstanceMethods
    # Get the weighted average of column(s).
    #
    # In addition to the options available on WeightedAverage::ArelSelectManagerInstanceMethods#weighted_average, this ActiveRecord-specific method understands associations.
    #
    # @param [Symbol,Array<Symbol>] data_column_names One or more column names whose average should be calculated. Added together before being multiplied by the weighting if more than one.
    # @param [Hash] options
    #
    # @option options [Symbol] :weighted_by The name of an association to weight against OR a column name just like in the pure ARel version.
    # @option options [Array{Symbol,Symbol}] :weighted_by The name of an association and a weighting column inside that association table to weight against. Not available in the pure ARel version.
    # @option options [Symbol] :disaggregate_by Same as its meaning in the pure ARel version.
    #
    # @example Get the average m3 of all aircraft, weighted by a column named :weighting in flight segments table. But wait... there is no column called :weighting! So see the next example.
    #   Aircraft.weighted_average(:m3, :weighted_by => :segments)
    #
    # @example Get the average m3 of all aircraft, weighted by how many :passengers flew in a particular aircraft.
    #   Aircraft.weighted_average(:m3, :weighted_by => [:segments, :passengers])
    #
    # @see WeightedAverage::ArelSelectManagerInstanceMethods#weighted_average The pure ARel version of this method, which doesn't know about associations
    #
    # @return [Float,nil]
    def weighted_average(data_column_names, options = {})
      weighted_average = connection.select_value weighted_average_relation(data_column_names, options).to_sql
      weighted_average.nil? ? nil : weighted_average.to_f
    end

    # Same as WeightedAverage::ArelSelectManagerInstanceMethods#weighted_average, except it can interpret associations.
    #
    # @see WeightedAverage::ArelSelectManagerInstanceMethods#weighted_average_relation The pure ARel version of this method.
    #
    # @return [Arel::SelectManager]
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
