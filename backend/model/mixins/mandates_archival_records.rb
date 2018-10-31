module MandatesArchivalRecords

  def self.included(base)
    base.include(Relationships)

    base.define_relationship(:name => :mandate_archival_record,
                             :json_property => 'mandates',
                             :contains_references_to_types => proc {[Mandate]})
  end

end
