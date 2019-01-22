require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:mandate) do
      primary_key :id

      String :title, null: false
      String :reference_number
      DynamicEnum :mandate_type_id
      MediumBlobField :note

      Integer :publish

      Integer :lock_version, default: 0, null: false
      Integer :json_schema_version, null: false

      apply_mtime_columns
    end

    alter_table(:date) do
      add_column(:mandate_id, :integer,  :null => true)
      add_foreign_key([:mandate_id], :mandate, :key => :id, :name => 'mandate_date_fk')
    end

    alter_table(:external_id) do
      add_column(:mandate_id, :integer,  :null => true)
      add_foreign_key([:mandate_id], :mandate, :key => :id, :name => 'mandate_external_id_fk')
    end

    create_editable_enum('mandate_type', ['legislation', 'regulation'])

    create_table(:function) do
      primary_key :id

      String :title, null: false

      Integer :lock_version, default: 0, null: false
      Integer :json_schema_version, null: false

      apply_mtime_columns
    end

    create_table(:mandate_function_rlshp) do
      primary_key :id
      Integer :mandate_id
      Integer :function_id

      Integer :aspace_relationship_position
      Integer :suppressed, null: false, default: 0

      apply_mtime_columns(false)
    end

    alter_table(:mandate_function_rlshp) do
      add_foreign_key([:mandate_id], :mandate, key: :id)
      add_foreign_key([:function_id], :function, key: :id)
    end

    create_table(:mandate_agency_rlshp) do
      primary_key :id
      Integer :mandate_id
      Integer :agent_corporate_entity_id

      Integer :aspace_relationship_position
      Integer :suppressed, null: false, default: 0

      apply_mtime_columns(false)
    end

    alter_table(:mandate_agency_rlshp) do
      add_foreign_key([:mandate_id], :mandate, key: :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, key: :id)
    end

    create_table(:mandate_archival_record_rlshp) do
      primary_key :id
      Integer :mandate_id
      Integer :resource_id
      Integer :archival_object_id

      Integer :aspace_relationship_position
      Integer :suppressed, null: false, default: 0

      apply_mtime_columns(false)
    end

    alter_table(:mandate_archival_record_rlshp) do
      add_foreign_key([:mandate_id], :mandate, key: :id)
      add_foreign_key([:resource_id], :resource, key: :id)
      add_foreign_key([:archival_object_id], :archival_object, key: :id)
    end

    create_table(:function_archival_record_rlshp) do
      primary_key :id
      Integer :function_id
      Integer :resource_id
      Integer :archival_object_id

      Integer :aspace_relationship_position
      Integer :suppressed, null: false, default: 0

      Date :start_date
      Date :end_date

      apply_mtime_columns(false)
    end

    alter_table(:function_archival_record_rlshp) do
      add_foreign_key([:function_id], :function, key: :id)
      add_foreign_key([:resource_id], :resource, key: :id)
      add_foreign_key([:archival_object_id], :archival_object, key: :id)
    end

    create_table(:function_agency_rlshp) do
      primary_key :id
      Integer :function_id
      Integer :agent_corporate_entity_id

      Integer :aspace_relationship_position
      Integer :suppressed, null: false, default: 0

      apply_mtime_columns(false)
    end

    alter_table(:function_agency_rlshp) do
      add_foreign_key([:function_id], :function, key: :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, key: :id)
    end
  end

  down do
    # Relationships
    drop_table(:mandate_function_rlshp)
    drop_table(:mandate_agency_rlshp)
    drop_table(:mandate_archival_record_rlshp)
    drop_table(:function_archival_record_rlshp)

    # Mandates
    alter_table(:date) do
      drop_constraint('mandate_date_fk')
    end

    alter_table(:external_id) do
      drop_constraint('mandate_external_id_fk')
    end

    if $db_type == :mysql
      self.run("alter table date drop foreign key mandate_date_fk")
      self.run("alter table external_id drop foreign key mandate_external_id_fk")
    end

    alter_table(:date) do
      drop_column(:mandate_id)
    end

    alter_table(:external_id) do
      drop_column(:mandate_id)
    end

    drop_table(:mandate)

    mandate_type_enum = self[:enumeration].filter(name => 'mandate_type')
    self[:enumeration_value].filter(:enumeration_id => mandate_type_enum.select(:id)).delete
    mandate_type_enum.delete

    # Functions
    drop_table(:function)
  end

end
