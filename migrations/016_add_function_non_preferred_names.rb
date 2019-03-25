require 'db/migrations/utils'

Sequel.migration do

  up do

    create_table(:function_non_preferred_name) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      Integer :function_id, :null => true

      String :name, :null => false

      apply_mtime_columns
    end


    alter_table(:function_non_preferred_name) do
      add_foreign_key([:function_id], :function, :key => :id)
    end
  end

  down do
  end

end
