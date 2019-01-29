{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "subtype" => "ref",
    "properties" => {
      "relator" => {
        "type" => "string",
        "dynamic_enum" => "function_nonpreferred_term_relator",
        "ifmissing" => "error"
      },

      "ref" => {
        "type" => [{"type" => "JSONModel(:function) uri"}],
        "ifmissing" => "error"
      },

      "_resolved" => {
        "type" => "object",
        "readonly" => "true"
      }
    }
  }
}
