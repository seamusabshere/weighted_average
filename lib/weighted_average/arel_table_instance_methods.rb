module WeightedAverage
  module ArelTableInstanceMethods
    # @see WeightedAverage::ArelSelectManagerInstanceMethods#weighted_average
    #
    # @return [Float,nil]
    def weighted_average(*args)
      from(self).weighted_average(*args)
    end

    # @see WeightedAverage::ArelSelectManagerInstanceMethods#weighted_average_relation
    #
    # @return [Arel::SelectManager]
    def weighted_average_relation(*args)
      from(self).weighted_average_relation(*args)
    end
  end
end
