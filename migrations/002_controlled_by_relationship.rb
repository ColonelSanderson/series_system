require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:controlled_by_rlshp) do
      primary_key :id

      Integer :agent_corporate_entity_id
      Integer :resource_id
      Integer :archival_object_id

      Integer :aspace_relationship_position
      Integer :suppressed, :null => false, :default => 0

      Date :start_date
      Date :end_date

      apply_mtime_columns(false)
    end

    alter_table(:controlled_by_rlshp) do
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
    end
  end


  # DOWN
  # drop table controlled_by_rlshp;
end
