module Mandates

  def self.included(base)
    base.include(Relationships)

    base.define_relationship(:name => :mandate,
                             :json_property => 'mandates',
                             :contains_references_to_types => proc {[Mandate]})
  end

end
