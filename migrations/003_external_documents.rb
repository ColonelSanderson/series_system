require 'db/migrations/utils'

Sequel.migration do
  records_supporting_ext_docs = [:function, :mandate]

  up do
    records_supporting_ext_docs.each do |record|
      alter_table(:external_document) do
        add_column("#{record}_id".intern, :integer, null: true)
        add_foreign_key(["#{record}_id".intern], record.intern, key: :id)
      end
    end

    create_table(:function_agency_rlshp) do
      primary_key :id
      Integer :function_id
      Integer :agent_corporate_entity_id

      Integer :aspace_relationship_position
      Integer :suppressed, null: false, default: 0

      Date :start_date
      Date :end_date

      apply_mtime_columns(false)
    end

    alter_table(:function_agency_rlshp) do
      add_foreign_key([:function_id], :function, key: :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, key: :id)
    end
  end
end
