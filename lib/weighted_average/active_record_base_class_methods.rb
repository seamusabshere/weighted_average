module WeightedAverage
  module ActiveRecordBaseClassMethods
    def weighted_average(*args)
      scoped.weighted_average(*args)
    end
    
    def weighted_average_relation(*args)
      scoped.weighted_average_relation(*args)
    end
  end
end
