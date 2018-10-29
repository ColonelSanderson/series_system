module ControlledByAgent

  def self.included(base)
    base.include(Relationships)

    base.define_relationship(:name => :controlled_by,
                             :json_property => 'controlled_by',
                             :contains_references_to_types => proc {[AgentCorporateEntity]})
  end

end