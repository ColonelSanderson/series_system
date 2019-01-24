{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "relator" => {
        "type" => "string",
        "dynamic_enum" => "function_preferred_term_relator",
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
