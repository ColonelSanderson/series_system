require 'db/migrations/utils'

Sequel.migration do
  up do
    alter_table(:date) do
      rename_column(:inferred_date_source, :date_notes)
    end
  end
end
