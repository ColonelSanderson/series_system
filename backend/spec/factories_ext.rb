require 'factory_bot'
require 'spec/lib/factory_bot_helpers'

FactoryBot.define do

  def JSONModel(key)
    JSONModel::JSONModel(key)
  end

  to_create{|instance| instance.save}

  sequence(:incremental_date) { |n| Time.at(Time.now.to_i + (n * 3600 * 24)).to_s.sub(/\s.*/, '') }
  sequence(:mandate_type) { sample(JSONModel(:mandate).schema['properties']['mandate_type']) }

  if defined? ASModel
    factory :function do
      uri { generate(:url) }
      title { generate(:generic_title) }
      description { generate(:generic_description) }
      identifier { generate(:string) }
      start_date { generate(:incremental_date) }
      end_date { generate(:incremental_date) }
    end

    factory :mandate do
      title { generate(:generic_title) }
      uri { generate(:url) }
      mandate_type { generate(:mandate_type) }
      description { generate(:generic_description) }
      identifier { generate(:string) }
      start_date { generate(:incremental_date) }
      end_date { generate(:incremental_date) }
    end

    factory :json_function, class: JSONModel(:function) do
      uri { generate(:url) }
      title { generate(:generic_title) }
      description { generate(:generic_description) }
      start_date { generate(:incremental_date) }
      end_date { generate(:incremental_date) }
      identifier { generate(:string) }
    end

    factory :json_mandate, class: JSONModel(:mandate) do
      uri { generate(:url) }
      title { generate(:generic_title) }
      mandate_type { generate(:mandate_type) }
      description { generate(:generic_description) }
      start_date { generate(:incremental_date) }
      end_date { generate(:incremental_date) }
      identifier { generate(:string) }
    end
  end
end
