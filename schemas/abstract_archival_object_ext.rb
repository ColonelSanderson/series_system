{
  "responsible_agency" => {
    "type" => "object",
    "subtype" => "ref",
    "properties" => {
      "ref" => {
        "type" => [{"type" => "JSONModel(:agent_corporate_entity) uri"}],
        "readonly" => "true"
      },
      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  },
  "recent_responsible_agencies" => {
    "type" => "object",
    "subtype" => "ref",
    "properties" => {
      "ref" => {
        "type" => [{"type" => "JSONModel(:agent_corporate_entity) uri"}],
        "readonly" => "true"
      },
      "end_date" => {
        "type" => "date",
        "readonly" => "true"
      },
      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  }
}
