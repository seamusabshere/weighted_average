module WeightedAverage
  module ArelSelectManagerInstanceMethods
    # Returns a number.
    def weighted_average(*args)
      weighted_average = @engine.connection.select_value(weighted_average_relation(*args).to_sql)
      weighted_average.nil? ? nil : weighted_average.to_f
    end

    # Returns the ARel relation for a weighted average query.
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
