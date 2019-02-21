require 'factory_bot'
require 'spec/lib/factory_bot_helpers'

FactoryBot.define do

  def JSONModel(key)
    JSONModel::JSONModel(key)
  end

  to_create{|instance| instance.save}

  sequence(:mandate_type) { sample(JSONModel(:mandate).schema['properties']['mandate_type']) }
  sequence(:function_source) { sample(JSONModel(:function).schema['properties']['source']) }

  if defined? ASModel
    factory :json_function, class: JSONModel(:function) do
      uri { generate(:url) }
      title { generate(:generic_title) }
      source { generate(:function_source) }
    end

    factory :json_mandate, class: JSONModel(:mandate) do
      uri { generate(:url) }
      title { generate(:generic_title) }
      mandate_type { generate(:mandate_type) }
      note { generate(:generic_description) }
      reference_number { generate(:string) }
      date { build(:json_date) }
    end
  end
end
