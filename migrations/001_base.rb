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

    create_editable_enum('mandate_type', ['legislation', 'regulation'])

    create_table(:function) do
      primary_key :id

      String :title, null: false
      MediumBlobField :note
      DynamicEnum :source_id

      Integer :publish

      Integer :lock_version, default: 0, null: false
      Integer :json_schema_version, null: false

      apply_mtime_columns
    end

    create_editable_enum('function_source', ['agift', 'qsa_specific'])

    create_enum("function_preferred_term_relator", ["has_preferred_term_of", "is_preferred_term_of"])
    create_enum("function_nonpreferred_term_relator", ["has_nonpreferred_term_of", "is_nonpreferred_term_of"])
    create_enum("function_synonym_relator", ["is_synonym_of"])

    create_table(:related_function_rlshp) do
      primary_key :id

      Integer :function_id_0
      Integer :function_id_1

      DynamicEnum :relator_id, :null => false

      String :relationship_target_record_type, :null => false
      Integer :relationship_target_id, :null => false
      String :jsonmodel_type, :null => false

      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:related_function_rlshp) do
      add_foreign_key([:function_id_0], :function, :key => :id)
      add_foreign_key([:function_id_1], :function, :key => :id)
    end

    alter_table(:date) do
      add_column(:mandate_id, :integer,  :null => true)
      add_column(:function_id, :integer,  :null => true)
      add_foreign_key([:mandate_id], :mandate, :key => :id, :name => 'mandate_date_fk')
      add_foreign_key([:function_id], :function, :key => :id, :name => 'function_date_fk')
    end

    alter_table(:external_id) do
      add_column(:mandate_id, :integer,  :null => true)
      add_foreign_key([:mandate_id], :mandate, :key => :id, :name => 'mandate_external_id_fk')
    end

    create_table(:mandate_function_rlshp) do
      primary_key :id
      Integer :mandate_id
      Integer :function_id

      Date :start_date
      Date :end_date

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

      Date :start_date
      Date :end_date

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

      Date :start_date
      Date :end_date

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

      Date :start_date
      Date :end_date

      Integer :aspace_relationship_position
      Integer :suppressed, null: false, default: 0

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

      Date :start_date
      Date :end_date

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
    drop_table(:function_agency_rlshp)
    drop_table(:function_archival_record_rlshp)

    # Mandates
    alter_table(:date) do
      drop_constraint('mandate_date_fk')
      drop_constraint('function_date_fk')
    end

    alter_table(:external_id) do
      drop_constraint('mandate_external_id_fk')
    end

    if $db_type == :mysql
      self.run("alter table date drop foreign key mandate_date_fk")
      self.run("alter table date drop foreign key function_date_fk")
      self.run("alter table external_id drop foreign key mandate_external_id_fk")
    end

    alter_table(:date) do
      drop_column(:mandate_id)
      drop_column(:function_id)
    end

    alter_table(:external_id) do
      drop_column(:mandate_id)
    end

    drop_table(:mandate)

    ['function_source', 'mandate_type', 'function_preferred_term_relator',
    'function_nonpreferred_term_relator', 'function_synonym_relator'].each do |enum_name|
      mandate_type_enum = self[:enumeration].filter(:name => enum_name)
      self[:enumeration_value].filter(:enumeration_id => mandate_type_enum.select(:id)).delete
      mandate_type_enum.delete
    end

    # Functions
    drop_table(:related_function_rlshp)
    drop_table(:function)
  end

end
