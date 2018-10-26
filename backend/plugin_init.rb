Permission.define("manage_function_record",
                  "The ability to create, modify and delete a function record",
                  :level => "repository")

Permission.define("update_function_record",
                  "The ability to create and modify function records",
                  :implied_by => 'manage_function_record',
                  :level => "global")

Permission.define("delete_function_record",
                  "The ability to create and modify function records",
                  :implied_by => 'manage_function_record',
                  :level => "global")

Permission.define("manage_mandate_record",
                  "The ability to create, modify and delete a function record",
                  :level => "repository")

Permission.define("update_mandate_record",
                  "The ability to create and modify function records",
                  :implied_by => 'manage_mandate_record',
                  :level => "global")

Permission.define("delete_mandate_record",
                  "The ability to create and modify function records",
                  :implied_by => 'manage_mandate_record',
                  :level => "global")
