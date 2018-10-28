class Function < Sequel::Model(:function)
  include ASModel
  include Relationships

  set_model_scope :global
  corresponds_to JSONModel(:function)

  define_relationship(:name => :mandate_function,
                      :json_property => 'mandates',
                      :contains_references_to_types => proc {[Mandate]})

  define_relationship(:name => :function,
                      :json_property => 'linked_agents',
                      :contains_references_to_types => proc {[AgentCorporateEntity]})


  def self.handle_delete(ids_to_delete)
    self.db[:function_rlshp].filter(:function_id => ids_to_delete).delete

    super
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.each do |json|
      # FIXME filter out malformed uris for non-agent linked records!
      json['linked_agents'].reject!{|ref| !ref['ref'].is_a?(String)}
    end

    jsons
  end

end
