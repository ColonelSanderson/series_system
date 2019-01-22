class Function < Sequel::Model(:function)
  include ASModel
  include Relationships

  set_model_scope :global
  corresponds_to JSONModel(:function)

  define_relationship(name: :mandate_function,
                      json_property: 'mandates',
                      contains_references_to_types: proc { [Mandate] })

  define_relationship(name: :function_agency,
                      contains_references_to_types: proc { [AgentCorporateEntity] })

  define_relationship(name: :function_archival_record,
                      contains_references_to_types: proc { [Resource, ArchivalObject] })

end
