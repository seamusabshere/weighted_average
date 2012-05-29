module WeightedAverage
  module ArelTableInstanceMethods
    def weighted_average(*args)
      from(self).weighted_average(*args)
    end

    # Returns the ARel relation for a weighted average query.
    def weighted_average_relation(data_column_names, options = {})
      from(self).weighted_average_relation(data_column_names, options)
    end
  end
end
