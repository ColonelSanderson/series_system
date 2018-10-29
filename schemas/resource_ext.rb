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
        "start_date" => {"type" => "date"},
        "end_date" => {"type" => "date"},
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
        "start_date" => {"type" => "date"},
        "end_date" => {"type" => "date"},
        "_resolved" => {
          "type" => "object",
          "readonly" => "true"
        }
      }
    }
  },
  "controlled_by" => {
    "type" => "array",
    "items" => {
      "type" => "object",
      "subtype" => "ref",
      "properties" => {
        "ref" => {
          "type" => "JSONModel(:agent_corporate_entity) uri",
          "ifmissing" => "error"
        },
        "start_date" => {"type" => "date"},
        "end_date" => {"type" => "date"},
        "current" => {
          "type" => "boolean",
          "readonly" => "true",
        },
        "_resolved" => {
          "type" => "object",
          "readonly" => "true"
        }
      }
    }
  },
}
