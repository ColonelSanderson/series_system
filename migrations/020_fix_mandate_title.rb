require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:mandate) do
      set_column_type(:title, String, :null => false, :size => 16384)
    end

  end

  down do
  end

end
