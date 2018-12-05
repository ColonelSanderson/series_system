require 'db/migrations/utils'

Sequel.migration do
  up do
    alter_table(:function) do
      add_unique_constraint(:title, :name => "function_name_uniq")
    end

    alter_table(:mandate) do
      add_unique_constraint(:title, :name => "mandate_name_uniq")
    end

    create_table(:location_rlshp) do
      primary_key :id

      Integer :location_id
      Integer :function_id, null: true
      Integer :mandate_id, null: true
      Integer :aspace_relationship_position

      Integer :suppressed, :null => false, :default => 0

      apply_mtime_columns(false)
    end

    alter_table(:location_rlshp) do
      add_foreign_key([:location_id], :location, :key => :id)
      add_foreign_key([:function_id], :function, :key => :id)
      add_foreign_key([:mandate_id], :function, :key => :id)
    end
  end
end
