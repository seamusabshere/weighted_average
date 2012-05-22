module WeightedAverage
  module ArelTableInstanceMethods
    # Returns a number.
    def weighted_average(*args)
      weighted_average = engine.connection.select_value(weighted_average_relation(*args).to_sql, 'weighted_average')
      weighted_average.nil? ? nil : weighted_average.to_f
    end

    # Returns the ARel relation for a weighted average query.
    def weighted_average_relation(data_column_names, options = {})
      weighted_by_column = self[options.fetch(:weighted_by, DEFAULT_WEIGHTED_BY_COLUMN_NAME)]
      
      disaggregate_by_column = if options[:disaggregate_by]
        self[options[:disaggregate_by]]
      end

      data_columns = ::Array.wrap(data_column_names).map do |data_column_name|
        self[data_column_name]
      end

      relation = if disaggregate_by_column
        project Arel::Nodes::Division.new(Arel::Nodes::Sum.new(weighted_by_column * (data_columns.inject(:+)) / disaggregate_by_column * 1.0), Arel::Nodes::Sum.new([weighted_by_column]))
      else
        project Arel::Nodes::Division.new(Arel::Nodes::Sum.new(weighted_by_column * (data_columns.inject(:+)) * 1.0), Arel::Nodes::Sum.new([weighted_by_column]))
      end

      data_columns.each do |data_column|
        relation = relation.where data_column.not_eq(nil)
      end

      # avoid division by zero
      relation = relation.where weighted_by_column.gt(0)
      if disaggregate_by_column
        relation = relation.where disaggregate_by_column.gt(0)
      end
      
      relation
    end

  end
end
