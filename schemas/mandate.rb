{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/mandates",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "title" => {"type" => "string", "minLength" => 1, "maxLength" => 16384, "ifmissing" => "error"},
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

    "additionalProperties" => false,
  },
}
