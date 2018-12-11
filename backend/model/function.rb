class Function < Sequel::Model(:function)
  include ASModel
  include Relationships
  include ExternalDocuments

  set_model_scope :global
  corresponds_to JSONModel(:function)

  define_relationship(name: :mandate_function,
                      json_property: 'mandates',
                      contains_references_to_types: proc { [Mandate] })

  define_relationship(name: :function_agency,
                      contains_references_to_types: proc { [AgentCorporateEntity] })

  define_relationship(name: :location,
                      json_property: 'location',
                      contains_references_to_types: proc { [Location] },
                      is_array: false)

  define_relationship(name: :function_archival_record,
                      contains_references_to_types: proc { [ArchivalObject] })

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.each do |json|
      # FIXME: filter out malformed uris for non-agent linked records!
      json['linked_agents'].select! { |ref| ref['ref'].is_a?(String) }
    end

    jsons
  end

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
