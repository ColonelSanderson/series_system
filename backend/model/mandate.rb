class Mandate < Sequel::Model(:mandate)
  include ASModel
  include Relationships
  include ExternalDocuments

  set_model_scope :global
  corresponds_to JSONModel(:mandate)

  define_relationship(name: :mandate_function,
                      json_property: 'functions',
                      contains_references_to_types: proc { [Function] })

  define_relationship(name: :mandate_agency,
                      json_property: 'linked_agents',
                      contains_references_to_types: proc { [AgentCorporateEntity] })

  define_relationship(name: :location,
                      json_property: 'location',
                      contains_references_to_types: proc { [Location] },
                      is_array: false)

  def validate
    validates_unique([:identifier], message: 'Identifier must be unique.')
    end_date_validation
    super
  end

  def end_date_validation
    if end_date && end_date < start_date
      errors.add(:start_date, 'End date must occur after start date')
      errors.add(:end_date, 'End date must occur after start date')
    end
  end
end
