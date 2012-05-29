module WeightedAverage
  module ActiveRecordBaseClassMethods
    # @see WeightedAverage::ActiveRecordRelationInstanceMethods#weighted_average
    #
    # @return [Float,nil]
    def weighted_average(*args)
      scoped.weighted_average(*args)
    end
    
    # @see WeightedAverage::ActiveRecordRelationInstanceMethods#weighted_average_relation
    #
    # @return [Arel::SelectManager]
    def weighted_average_relation(*args)
      scoped.weighted_average_relation(*args)
    end
  end
end
