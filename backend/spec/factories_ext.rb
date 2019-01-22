require 'factory_bot'
require 'spec/lib/factory_bot_helpers'

FactoryBot.define do

  def JSONModel(key)
    JSONModel::JSONModel(key)
  end

  to_create{|instance| instance.save}

  sequence(:mandate_type) { sample(JSONModel(:mandate).schema['properties']['mandate_type']) }

  if defined? ASModel
    factory :function do
      uri { generate(:url) }
      title { generate(:generic_title) }
    end

    factory :mandate do
      uri { generate(:url) }
      title { generate(:generic_title) }
      mandate_type { generate(:mandate_type) }
      note { generate(:generic_description) }
      reference_number { generate(:string) }
      date { build(:json_date) }
    end

    factory :json_function, class: JSONModel(:function) do
      uri { generate(:url) }
      title { generate(:generic_title) }
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
