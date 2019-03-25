class FunctionNonPreferredName < Sequel::Model(:function_non_preferred_name)
  include ASModel
  corresponds_to JSONModel(:function_non_preferred_name)

  set_model_scope :global
end