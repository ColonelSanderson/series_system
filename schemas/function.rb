{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/functions",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "title" => {"type" => "string", "minLength" => 1, "maxLength" => 16384, "ifmissing" => "error"},
      "mandates" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "properties" => {
            "ref" => {
              "type" => "JSONModel(:mandates) uri",
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
      "linked_agents" => {
        "type" => "array",
        "items" => {
          "type" => "object",
          "subtype" => "ref",
          "readonly" => "true",
          "properties" => {
            "ref" => {"type" => "JSONModel(:agent_corporate_entity) uri"},
            "start_date" => {"type" => "date"},
            "end_date" => {"type" => "date"},
            "_resolved" => {
              "type" => "object",
              "readonly" => "true"
            }
          }
        }
      },
      "identifier" => {"type" => "string", "ifmissing" => "error"},
      "start_date" => {"type" => "date", "ifmissing" => "error"},
      "end_date" => {"type" => "date"},
      "description" => {"type" => "string", "ifmissing" => "error", "maxLength" => 16384},
      "external_documents" => {
        "type" => "array",
        "items" => {
          "type" => "JSONModel(:external_document) object"
        }
      }
    },
    "additionalProperties" => false
  }
}
