module WeightedAverage
  module ActiveRecordBaseClassMethods
    def weighted_average(*args) # :nodoc:
      scoped.weighted_average(*args)
    end
    
    def weighted_average_relation(*args) # :nodoc:
      scoped.weighted_average_relation(*args)
    end
  end
end
