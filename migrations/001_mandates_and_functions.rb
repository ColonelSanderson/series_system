require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:mandate) do
      primary_key :id

      String :title
      DynamicEnum :mandate_type_id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      apply_mtime_columns
    end

    create_editable_enum('mandate_type', ['legislation','not_legislation'])

    create_table(:function) do
      primary_key :id

      String :title
      String :description
      String :identifier, :unique => true
      Date :start_date, :null => false
      Date :end_date

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      apply_mtime_columns
    end

    create_table(:mandate_function_rlshp) do
      primary_key :id
      Integer :mandate_id
      Integer :function_id

      Integer :aspace_relationship_position
      Integer :suppressed, :null => false, :default => 0

      Date :start_date
      Date :end_date

      apply_mtime_columns(false)
    end

    alter_table(:mandate_function_rlshp) do
      add_foreign_key([:mandate_id], :mandate, :key => :id)
      add_foreign_key([:function_id], :function, :key => :id)
    end

    create_table(:mandate_agency_rlshp) do
      primary_key :id
      Integer :mandate_id
      Integer :agent_corporate_entity_id

      Integer :aspace_relationship_position
      Integer :suppressed, :null => false, :default => 0

      Date :start_date
      Date :end_date

      apply_mtime_columns(false)
    end

    alter_table(:mandate_agency_rlshp) do
      add_foreign_key([:mandate_id], :mandate, :key => :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
    end

    create_table(:mandate_archival_record_rlshp) do
      primary_key :id
      Integer :mandate_id
      Integer :resource_id
      Integer :archival_object_id

      Integer :aspace_relationship_position
      Integer :suppressed, :null => false, :default => 0

      Date :start_date
      Date :end_date

      apply_mtime_columns(false)
    end

    alter_table(:mandate_archival_record_rlshp) do
      add_foreign_key([:mandate_id], :mandate, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
    end

    create_table(:function_archival_record_rlshp) do
      primary_key :id
      Integer :function_id
      Integer :resource_id
      Integer :archival_object_id

      Integer :aspace_relationship_position
      Integer :suppressed, :null => false, :default => 0

      Date :start_date
      Date :end_date
      
      apply_mtime_columns(false)
    end

    alter_table(:function_archival_record_rlshp) do
      add_foreign_key([:function_id], :function, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
    end
  end


  # DOWN
  # drop table mandate_function_rlshp;
  # drop table mandate_agency_rlshp;
  # drop table mandate_archival_record_rlshp;
  # drop table function_archival_record_rlshp;
  # drop table function;
  # drop table mandate;
  # drop table series_system_schema_info;
  # delete from enumeration_value where enumeration_id in (select id from enumeration where name = 'mandate_type');
  # delete from enumeration where name = 'mandate_type';
end
