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

      "display_string" => {"type" => "string", "readonly" => true},

      "date" => {"type" => "JSONModel(:date) object"},
      "non_preferred_names" => {"type" => "array", "items" => {"type" => "JSONModel(:function_non_preferred_name) object"}}
    },
    "additionalProperties" => false
  }
}
