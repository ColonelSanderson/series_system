module FunctionsArchivalRecords

  def self.included(base)
    base.include(Relationships)

    base.define_relationship(:name => :function_archival_record,
                             :json_property => 'functions',
                             :contains_references_to_types => proc {[Function]})
  end

end
