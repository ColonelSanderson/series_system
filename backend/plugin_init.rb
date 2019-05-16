require_relative 'lib/date_parse'
require_relative 'lib/date_range'

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

require_relative '../lib/relationship_rules'
RelationshipRules.instance.bootstrap!

require_relative '../lib/validations'
include SeriesSystemValidations

begin
  History.register_model(Mandate)
  History.register_model(Function)
  History.add_diff_skip_field(:relationship_id)
rescue NameError
  Log.info("Unable to register Mandate and Function for history. Please install the as_history plugin")
end
