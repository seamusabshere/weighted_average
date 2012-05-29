require 'arel'
require 'active_support/core_ext'

module WeightedAverage
  DEFAULT_WEIGHTED_BY_COLUMN_NAME = :weighting
end

require 'weighted_average/arel_select_manager_instance_methods'
Arel::SelectManager.send :include, WeightedAverage::ArelSelectManagerInstanceMethods

require 'weighted_average/arel_table_instance_methods'
Arel::Table.send :include, WeightedAverage::ArelTableInstanceMethods

if defined?(ActiveRecord)
  require 'weighted_average/active_record_base_class_methods'
  ActiveRecord::Base.extend WeightedAverage::ActiveRecordBaseClassMethods
  proxy_class = defined?(ActiveRecord::Associations::CollectionProxy) ? ActiveRecord::Associations::CollectionProxy : ActiveRecord::Associations::AssociationCollection
  proxy_class.extend WeightedAverage::ActiveRecordBaseClassMethods

  require 'weighted_average/active_record_relation_instance_methods'
  ActiveRecord::Relation.send :include, WeightedAverage::ActiveRecordRelationInstanceMethods
end
