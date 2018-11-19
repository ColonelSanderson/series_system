require 'db/migrations/utils'

Sequel.migration do
  records_supporting_external_documents = [:function]

  up do
    records_supporting_external_documents.each do |record|
      alter_table(:external_document) do
        add_column("#{record}_id".intern, :integer, :null => true)
        add_foreign_key(["#{record}_id".intern], record.intern, :key => :id)

        apply_mtime_columns
      end
    end
  end

  down do
    records_supporting_external_documents.each do |record|
      alter_table(record.intern) do
        drop_constraint("#{record}_external_document_fk")
        drop_column("#{record}_id".intern)
      end
    end
  end
end
