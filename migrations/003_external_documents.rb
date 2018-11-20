require 'db/migrations/utils'

Sequel.migration do
  records_supporting_external_documents = [:function]

  up do
    records_supporting_external_documents.each do |record|
      alter_table(:external_document) do
        add_column("#{record}_id".intern, :integer, :null => true)
        add_foreign_key(["#{record}_id".intern], record.intern, :key => :id)
      end
    end
  end
end
