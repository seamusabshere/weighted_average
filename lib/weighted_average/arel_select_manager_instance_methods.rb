module WeightedAverage
  module ArelSelectManagerInstanceMethods
    # Calculate the weighted average of column(s).
    #
    # @param [Symbol,Array<Symbol>] data_column_names One or more column names whose average should be calculated. Added together before being multiplied by the weighting if more than one.
    # @param [Hash] options
    #
    # @option options [Symbol] :weighted_by The name of the weighting column if it's not :weighting (the default)
    # @option options [Symbol] :disaggregate_by The name of a column to disaggregate by. Usually not necessary.
    #
    # @see WeightedAverage::ActiveRecordRelationInstanceMethods The ActiveRecord-specific version of this method, which knows about associations.
    #
    # @example Weighted average of load factor in flight stage data
    #   Arel::Table.new(:flight_segments).weighted_average(:load_factor, :weighted_by => :passengers)
    #
    # @return [Float,nil]
    def weighted_average(data_column_names, options = {})
      weighted_average = @engine.connection.select_value(weighted_average_relation(data_column_names, options).to_sql)
      weighted_average.nil? ? nil : weighted_average.to_f
    end

    # In case you want to get the relation and/or the SQL of the calculation query before actually runnnig it.
    #
    # @example Get the SQL
    #   Arel::Table.new(:flight_segments).weighted_average_relation(:load_factor, :weighted_by => :passengers).to_sql
    #
    # @return [Arel::SelectManager] A relation you can play around with.
    def weighted_average_relation(data_column_names, options = {})
      left = self.source.left

      weighted_by_column = case options[:weighted_by]
      when Arel::Attribute
        options[:weighted_by]
      when Symbol, String
        left[options[:weighted_by]]
      when NilClass
        left[DEFAULT_WEIGHTED_BY_COLUMN_NAME]
      else
        raise ArgumentError, ":weighted_by => #{options[:weighted_by].inspect} must be a column on #{left.inspect}"
      end
      
      disaggregate_by_column = if options[:disaggregate_by]
        left[options[:disaggregate_by]]
      end

      data_columns = ::Array.wrap(data_column_names).map do |data_column_name|
        left[data_column_name]
      end

      if disaggregate_by_column
        self.projections = [Arel::Nodes::Division.new(Arel::Nodes::Sum.new(weighted_by_column * (data_columns.inject(:+)) / disaggregate_by_column * 1.0), Arel::Nodes::Sum.new([weighted_by_column]))]
      else
        self.projections = [Arel::Nodes::Division.new(Arel::Nodes::Sum.new(weighted_by_column * (data_columns.inject(:+)) * 1.0), Arel::Nodes::Sum.new([weighted_by_column]))]
      end

      data_columns_not_eq_nil = data_columns.inject(nil) do |memo, data_column|
        if memo
          memo.and(data_column.not_eq(nil))
        else
          data_column.not_eq(nil)
        end
      end

      if disaggregate_by_column
        where data_columns_not_eq_nil.and(weighted_by_column.gt(0)).and(disaggregate_by_column.gt(0))
      else
        where data_columns_not_eq_nil.and(weighted_by_column.gt(0))
      end
    end

  end
end
