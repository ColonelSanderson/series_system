require 'db/migrations/utils'

Sequel.migration do
  up do

    alter_table(:function) do
      set_column_type :note, :text
    end

    alter_table(:mandate) do
      set_column_type :note, :text
    end

  end
end
