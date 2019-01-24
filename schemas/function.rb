{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/functions",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "title" => {"type" => "string", "minLength" => 1, "maxLength" => 16384, "ifmissing" => "error"},
      "source" => {"type" => "string", "dynamic_enum" => "function_source"},
      "note" => {"type" => "string", "maxLength" => 16384},
      "publish" => {"type" => "boolean"},

      "date" => {"type" => "JSONModel(:date) object"},

      "related_functions" => {
        "type" => "array",
        "items" => {"type" => [{"type" => "JSONModel(:function_synonym_relationship) object"},
                               {"type" => "JSONModel(:function_preferred_term_relationship) object"},
                               {"type" => "JSONModel(:function_nonpreferred_term_relationship) object"}]},
      },

      "mandates" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => "JSONModel(:mandate) uri",
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
