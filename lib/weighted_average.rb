require 'arel'
require 'active_support/core_ext'
require 'active_record'

require 'weighted_average/active_record_base_class_methods'
require 'weighted_average/active_record_relation_instance_methods'
require 'weighted_average/arel_table_instance_methods'

module WeightedAverage
  DEFAULT_WEIGHTED_BY_COLUMN_NAME = :weighting
end

ActiveRecord::Base.extend WeightedAverage::ActiveRecordBaseClassMethods

proxy_class = defined?(ActiveRecord::Associations::CollectionProxy) ? ActiveRecord::Associations::CollectionProxy : ActiveRecord::Associations::AssociationCollection
proxy_class.extend WeightedAverage::ActiveRecordBaseClassMethods

ActiveRecord::Relation.send :include, WeightedAverage::ActiveRecordRelationInstanceMethods
Arel::Table.send :include, WeightedAverage::ArelTableInstanceMethods
