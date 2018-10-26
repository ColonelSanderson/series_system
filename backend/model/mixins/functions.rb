module Functions

  def self.included(base)
    base.include(Relationships)

    base.define_relationship(:name => :function,
                             :json_property => 'functions',
                             :contains_references_to_types => proc {[Function]})
  end

end
