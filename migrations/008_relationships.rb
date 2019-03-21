require 'db/migrations/utils'

Sequel.migration do
  up do
    create_table(:series_system_rlshp) do
      primary_key :id

      Integer :accession_id_0
      Integer :accession_id_1
      Integer :resource_id_0
      Integer :resource_id_1
      Integer :archival_object_id_0
      Integer :archival_object_id_1
      Integer :digital_object_id_0
      Integer :digital_object_id_1
      Integer :digital_object_component_id_0
      Integer :digital_object_component_id_1
      Integer :agent_corporate_entity_id_0
      Integer :agent_corporate_entity_id_1
      Integer :agent_family_id_0
      Integer :agent_family_id_1
      Integer :agent_person_id_0
      Integer :agent_person_id_1
      Integer :agent_software_id_0
      Integer :agent_software_id_1
      Integer :function_id_0
      Integer :function_id_1
      Integer :mandate_id_0
      Integer :mandate_id_1

      DynamicEnum :relator_id, :null => false

      String :start_date
      String :end_date

      TextField :note

      String :relationship_target_record_type, :null => false
      Integer :relationship_target_id, :null => false
      String :jsonmodel_type, :null => false

      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:series_system_rlshp) do
      add_foreign_key([:accession_id_0], :accession, :key => :id)
      add_foreign_key([:accession_id_1], :accession, :key => :id)
      add_foreign_key([:resource_id_0], :resource, :key => :id)
      add_foreign_key([:resource_id_1], :resource, :key => :id)
      add_foreign_key([:archival_object_id_0], :archival_object, :key => :id)
      add_foreign_key([:archival_object_id_1], :archival_object, :key => :id)
      add_foreign_key([:digital_object_id_0], :digital_object, :key => :id)
      add_foreign_key([:digital_object_id_1], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id_0], :digital_object_component, :key => :id)
      add_foreign_key([:digital_object_component_id_1], :digital_object_component, :key => :id)
      add_foreign_key([:agent_corporate_entity_id_0], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_corporate_entity_id_1], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_family_id_0], :agent_family, :key => :id)
      add_foreign_key([:agent_family_id_1], :agent_family, :key => :id)
      add_foreign_key([:agent_person_id_0], :agent_person, :key => :id)
      add_foreign_key([:agent_person_id_1], :agent_person, :key => :id)
      add_foreign_key([:agent_software_id_0], :agent_software, :key => :id)
      add_foreign_key([:agent_software_id_1], :agent_software, :key => :id)
      add_foreign_key([:function_id_0], :function, :key => :id)
      add_foreign_key([:function_id_1], :function, :key => :id)
      add_foreign_key([:mandate_id_0], :mandate, :key => :id)
      add_foreign_key([:mandate_id_1], :mandate, :key => :id)
    end

    create_enum("series_system_association_relator", ["is_associated_with"])
    create_enum("series_system_succession_relator", ["supercedes", "precedes"])
    create_enum("series_system_ownership_relator", ["controls", "is_controlled_by"])
    create_enum("series_system_containment_relator", ["contains", "is_contained_within"])
    create_enum("series_system_creation_relator", ["established", "established_by"])
    create_enum("series_system_responsibility_relator", ["is_responsible_for", "under_responsibility_of"])
    create_enum("series_system_represented_relator", ["represents", "is_represented_by"])
    create_enum("series_system_derivation_relator", ["derives", "is_derived_from"])
    create_enum("series_system_documentation_relator", ["documents", "is_documented_by"])
    create_enum("series_system_restriction_relator", ["restricts", "is_restricted_by"])

    series_system_association_relator_enum_id = self[:enumeration].filter(name: 'series_system_association_relator').select(:id).first[:id]
    is_associated_with_id = self[:enumeration_value].filter(enumeration_id: series_system_association_relator_enum_id, value: 'is_associated_with').select(:id).first[:id]

    series_system_ownership_relator_enum_id = self[:enumeration].filter(name: 'series_system_ownership_relator').select(:id).first[:id]
    is_controlled_by_id = self[:enumeration_value].filter(enumeration_id: series_system_ownership_relator_enum_id, value: 'is_controlled_by').select(:id).first[:id]

    # Migrate old rlshps to use series_system_rlshp
    self[:mandate_function_rlshp].all.each_with_index do |row, i|
      self[:series_system_rlshp].insert(
        mandate_id_0: row[:mandate_id], 
        function_id_0: row[:function_id],
        relator_id: is_associated_with_id,
        start_date: row[:start_date] ? row[:start_date].strftime('%Y-%m-%d') : nil,
        end_date: row[:end_date] ? row[:end_date].strftime('%Y-%m-%d') : nil,
        relationship_target_record_type: 'function',
        relationship_target_id: row[:function_id],
        jsonmodel_type: 'series_system_function_mandate_association_relationship',
        aspace_relationship_position: i,
        created_by: row[:created_by],
        last_modified_by: row[:last_modified_by],
        system_mtime: row[:system_mtime],
        user_mtime: row[:user_mtime],
      )
    end

    self[:mandate_agency_rlshp].all.each_with_index do |row, i|
      self[:series_system_rlshp].insert(
        mandate_id_0: row[:mandate_id],
        agent_corporate_entity_id_0: row[:agent_corporate_entity_id],
        relator_id: is_controlled_by_id,
        start_date: row[:start_date] ? row[:start_date].strftime('%Y-%m-%d') : nil,
        end_date: row[:end_date] ? row[:end_date].strftime('%Y-%m-%d') : nil,
        relationship_target_record_type: 'agent_corporate_entity',
        relationship_target_id: row[:agent_corporate_entity_id],
        jsonmodel_type: 'series_system_agent_mandate_ownership_relationship',
        aspace_relationship_position: i,
        created_by: row[:created_by],
        last_modified_by: row[:last_modified_by],
        system_mtime: row[:system_mtime],
        user_mtime: row[:user_mtime],
        )
    end

    self[:mandate_archival_record_rlshp].each_with_index do |row, i|
      next if row[:archival_object_id]

      self[:series_system_rlshp].insert(
        mandate_id_0: row[:mandate_id],
        resource_id_0: row[:resource_id],
        relator_id: is_associated_with_id,
        start_date: row[:start_date] ? row[:start_date].strftime('%Y-%m-%d') : nil,
        end_date: row[:end_date] ? row[:end_date].strftime('%Y-%m-%d') : nil,
        relationship_target_record_type: 'resource',
        relationship_target_id: row[:resource_id],
        jsonmodel_type: 'series_system_mandate_series_association_relationship',
        aspace_relationship_position: i,
        created_by: row[:created_by],
        last_modified_by: row[:last_modified_by],
        system_mtime: row[:system_mtime],
        user_mtime: row[:user_mtime],
        )
    end

    self[:function_agency_rlshp].all.each_with_index do |row, i|
      self[:series_system_rlshp].insert(
        function_id_0: row[:function_id],
        agent_corporate_entity_id_0: row[:agent_corporate_entity_id],
        agent_family_id_0: row[:agent_family_id],
        agent_person_id_0: row[:agent_person_id],
        agent_software_id_0: row[:agent_software_id],
        relator_id: is_controlled_by_id,
        start_date: row[:start_date] ? row[:start_date].strftime('%Y-%m-%d') : nil,
        end_date: row[:end_date] ? row[:end_date].strftime('%Y-%m-%d') : nil,
        relationship_target_record_type: 'agent_corporate_entity',
        relationship_target_id: row[:agent_corporate_entity_id],
        jsonmodel_type: 'series_system_agent_function_ownership_relationship',
        aspace_relationship_position: i,
        created_by: row[:created_by],
        last_modified_by: row[:last_modified_by],
        system_mtime: row[:system_mtime],
        user_mtime: row[:user_mtime],
        )
    end

    self[:function_archival_record_rlshp].all.each_with_index do |row, i|
      next if row[:archival_object_id]

      self[:series_system_rlshp].insert(
        function_id_0: row[:function_id],
        resource_id_0: row[:resource_id],
        relator_id: is_associated_with_id,
        start_date: row[:start_date] ? row[:start_date].strftime('%Y-%m-%d') : nil,
        end_date: row[:end_date] ? row[:end_date].strftime('%Y-%m-%d') : nil,
        relationship_target_record_type: 'resource',
        relationship_target_id: row[:resource_id],
        jsonmodel_type: 'series_system_function_series_associated_relationship',
        aspace_relationship_position: i,
        created_by: row[:created_by],
        last_modified_by: row[:last_modified_by],
        system_mtime: row[:system_mtime],
        user_mtime: row[:user_mtime],
        )
    end

    # rename function relators
    self[:enumeration].filter(name: 'function_preferred_term_relator').update(name: 'series_system_preferred_term_relator')
    self[:enumeration].filter(name: 'function_nonpreferred_term_relator').update(name: 'series_system_nonpreferred_term_relator')

    self[:related_function_rlshp].all.each do |row|
      enum_name = self[:enumeration].filter(id: self[:enumeration_value].filter(id: row[:relator_id]).select(:enumeration_id)).select(:name).first[:name]
      jsonmodel_type = if enum_name == 'series_system_preferred_term_relator'
                         'series_system_function_function_preferred_term_relationship'
                       elsif enum_name == 'series_system_nonpreferred_term_relator'
                         'series_system_function_function_nonpreferred_term_relationship'
                       else
                        raise "WHAT: #{enum_name}"
                       end
      self[:series_system_rlshp].insert(
        function_id_0: row[:function_id_0],
        function_id_1: row[:function_id_1],
        relator_id: row[:relator_id],
        start_date: row[:start_date] ? row[:start_date].strftime('%Y-%m-%d') : nil,
        end_date: row[:end_date] ? row[:end_date].strftime('%Y-%m-%d') : nil,
        relationship_target_record_type: 'function',
        relationship_target_id: row[:relationship_target_id],
        jsonmodel_type: jsonmodel_type,
        aspace_relationship_position: row[:aspace_relationship_position],
        created_by: row[:created_by],
        last_modified_by: row[:last_modified_by],
        system_mtime: row[:system_mtime],
        user_mtime: row[:user_mtime],
        )
    end

    drop_table(:mandate_function_rlshp)
    drop_table(:mandate_agency_rlshp)
    drop_table(:mandate_archival_record_rlshp)
    drop_table(:function_agency_rlshp)
    drop_table(:function_archival_record_rlshp)
    drop_table(:related_function_rlshp)
  end
end
