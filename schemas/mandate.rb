{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/mandates",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "title" => {"type" => "string", "minLength" => 1, "maxLength" => 16384, "ifmissing" => "error"},
      "mandate_type" => {"type" => "string", "dynamic_enum" => "mandate_type", "ifmissing" => "error"},
      "reference_number" => {"type" => "string"},
      "publish" => {"type" => "boolean"},
      "note" => {"type" => "string", "maxLength" => 16384},

      "date" => {"type" => "JSONModel(:date) object"},
      "external_ids" => {"type" => "array", "items" => {"type" => "JSONModel(:external_id) object"}},

      "functions" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => "JSONModel(:function) uri",
              "ifmissing" => "error"
            },
            "start_date" => {"type" => "date"},
            "end_date" => {"type" => "date"},
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },
    },
    "additionalProperties" => false
  }
}
