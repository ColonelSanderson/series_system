require 'db/migrations/utils'

Sequel.migration do

  up do

    alter_table(:external_id) do
      add_column(:agent_corporate_entity_id, Integer, :null => true)
      add_column(:agent_family_id, Integer, :null => true)
      add_column(:agent_person_id, Integer, :null => true)
      add_column(:agent_software_id, Integer, :null => true)

      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
    end

  end

  down do
  end

end
