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
                      json_property: 'linked_agents',
                      contains_references_to_types: proc { [AgentCorporateEntity] })

  def self.handle_delete(ids_to_delete)
    db[:function_agency_rlshp].filter(function_id: ids_to_delete).delete
    db[:mandate_function_rlshp].filter(function_id: ids_to_delete).delete
    super
  end

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
    map_validation_to_json_property([:identifier], :identifier)
    map_validation_to_json_property([:end_date], :end_date)
    end_date_validation
    super
  end

  def end_date_validation
    if end_date && end_date < start_date
      errors.add(:field, 'End date must occur after start date')
    end
  end
end
