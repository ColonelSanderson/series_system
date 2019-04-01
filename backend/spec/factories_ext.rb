FactoryBot.modify do
  factory :json_resource, class: JSONModel::JSONModel(:resource) do
    self.series_system_agent_relationships {
      [
       {
         'jsonmodel_type' => 'series_system_agent_record_ownership_relationship',
         'relator' => 'is_controlled_by',
         'start_date' => generate(:yyyy_mm_dd),
         'ref' => create(:json_agent_corporate_entity).uri
       }
      ]
    }
  end

  factory :json_date, class: JSONModel::JSONModel(:date) do
    self.end { nil }
  end

  factory :json_agent_corporate_entity, class: JSONModel::JSONModel(:agent_corporate_entity) do
    self.dates_of_existence { [build(:json_date, {:label => 'existence'})] }
  end
end


FactoryBot.define do

  sequence(:mandate_type) { sample(JSONModel::JSONModel(:mandate).schema['properties']['mandate_type']) }
  sequence(:function_source) { sample(JSONModel::JSONModel(:function).schema['properties']['source']) }

  factory :json_function, class: JSONModel::JSONModel(:function) do
    uri { generate(:url) }
    title { generate(:generic_title) }
    source { generate(:function_source) }
  end

  factory :json_mandate, class: JSONModel::JSONModel(:mandate) do
    uri { generate(:url) }
    title { generate(:generic_title) }
    mandate_type { generate(:mandate_type) }
    note { generate(:generic_description) }
    reference_number { generate(:string) }
    date { build(:json_date) }
  end
end
