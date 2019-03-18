module HiddenFields
  CONFIG = {
    "agents" => {
      "agent_corporate_entity_names" => {
        "show" => [
          ["agent_names_", "_primary_name_"],
          ["agent_names_", "_subordinate_name_1_"],
          ["agent_names_", "_subordinate_name_2_"]
        ],
        "defaultValues" => [
          { "path" => ["agent_names_", "_source_"], "value" => "local" }
        ]
      },
      "agent_corporate_entity_dates_of_existence" => {
        "show" => [
          ["agent_dates_of_existence_", "_date_type_"],
          ["agent_dates_of_existence_", "_expression_"],
          ["agent_dates_of_existence_", "_begin_"],
          ["agent_dates_of_existence_", "_end_"],
          ["agent_dates_of_existence_", "_certainty_"],
          ["agent_dates_of_existence_", "_inferred_date_source_"]
        ],
        "defaultValues" => [
        ]
      }
    }
  }
end
