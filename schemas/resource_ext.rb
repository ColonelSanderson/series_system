{
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
        "_resolved" => {
          "type" => "object",
          "readonly" => "true"
        }
      }
    }
  },
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
        "_resolved" => {
          "type" => "object",
          "readonly" => "true"
        }
      }
    }
  },
}
