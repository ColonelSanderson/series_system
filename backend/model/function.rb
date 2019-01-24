class Function < Sequel::Model(:function)
  include ASModel
  include Relationships
  include Publishable
  include DirectionalRelationships

  set_model_scope :global
  corresponds_to JSONModel(:function)

  define_relationship(name: :mandate_function,
                      json_property: 'mandates',
                      contains_references_to_types: proc { [Mandate] })

  define_relationship(name: :function_agency,
                      contains_references_to_types: proc { [AgentCorporateEntity] })

  define_relationship(name: :function_archival_record,
                      contains_references_to_types: proc { [Resource, ArchivalObject] })

  one_to_one :date, :class => "ASDate"
  def_nested_record(:the_property => :date,
                    :contains_records_of_type => :date,
                    :corresponding_to_association => :date,
                    :is_array => false)

  define_directional_relationship(:name => :related_function,
                                  :json_property => 'related_functions',
                                  :contains_references_to_types => proc {[Function]},
                                  :class_callback => proc {|clz|
                                    clz.instance_eval do
                                      include DynamicEnums
                                      uses_enums({
                                                   :property => 'relator',
                                                   :uses_enum => ['function_preferred_term_relator', 'function_nonpreferred_term_relator', 'function_synonym_relator']
                                                 })
                                    end
                                  })

end
