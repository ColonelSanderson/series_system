{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "subtype" => "ref",
    "properties" => {
      "relationship_id" => {
        "type" => "string",
        "readonly" => "true",
      },
      "ref" => {
        "type" => [{"type" => "JSONModel(:accession) uri"},
                   {"type" => "JSONModel(:resource) uri"},
                   {"type" => "JSONModel(:archival_object) uri"},
                   {"type" => "JSONModel(:digital_object) uri"},
                   {"type" => "JSONModel(:digital_object_component) uri"},
                   {"type" => "JSONModel(:agent_corporate_entity) uri"},
                   {"type" => "JSONModel(:agent_family) uri"},
                   {"type" => "JSONModel(:agent_person) uri"},
                   {"type" => "JSONModel(:agent_software) uri"},
                   {"type" => "JSONModel(:function) uri"},
                   {"type" => "JSONModel(:mandate) uri"}],
        "ifmissing" => "error"
      },
      "start_date" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "end_date" => {"type" => "string", "maxLength" => 255},
      "note" => {"type" => "string", "maxLength" => 16384},

      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  }
}
