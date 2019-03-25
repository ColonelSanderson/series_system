{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "properties" => {
      "name" => {"type" => "string", "maxLength" => 16384, "ifmissing" => "error"},
    },
    "additionalProperties" => false
  }
}
