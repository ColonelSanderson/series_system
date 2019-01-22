class Mandate < Sequel::Model(:mandate)
  include ASModel
  include Relationships
  include ExternalIDs
  include Publishable

  set_model_scope :global
  corresponds_to JSONModel(:mandate)

  define_relationship(name: :mandate_function,
                      json_property: 'functions',
                      contains_references_to_types: proc { [Function] })

  define_relationship(name: :mandate_agency,
                      contains_references_to_types: proc { [AgentCorporateEntity] })

  define_relationship(name: :mandate_archival_record,
                      contains_references_to_types: proc { [Resource, ArchivalObject] })

  one_to_one :date, :class => "ASDate"
  def_nested_record(:the_property => :date,
                    :contains_records_of_type => :date,
                    :corresponding_to_association => :date,
                    :is_array => false)

end
