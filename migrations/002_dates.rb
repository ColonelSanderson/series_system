require 'db/migrations/utils'

Sequel.migration do
  up do
    alter_table(:date) do
      add_column(:inferred_date_source, String, null: true)
    end
  end
end
