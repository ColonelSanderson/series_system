class Function < Sequel::Model(:function)
  include ASModel
  include Relationships

  set_model_scope :global
  corresponds_to JSONModel(:function)

  define_relationship(:name => :mandate_function,
                      :json_property => 'mandates',
                      :contains_references_to_types => proc {[Mandate]})


  def self.handle_delete(ids_to_delete)
    self.db[:function_rlshp].filter(:function_id => ids_to_delete).delete

    super
  end

end
