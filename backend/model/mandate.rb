class Mandate < Sequel::Model(:mandate)
  include ASModel
  include Relationships

  set_model_scope :global
  corresponds_to JSONModel(:mandate)

  define_relationship(name: :mandate_function,
                      json_property: 'functions',
                      contains_references_to_types: proc { [Function] })

  define_relationship(name: :mandate_agency,
                      json_property: 'linked_agents',
                      contains_references_to_types: proc { [AgentCorporateEntity] })
end
