require 'db/migrations/utils'

Sequel.migration do
  up do

    alter_table(:function) do
      if $db_type == :mysql
        set_column_type :note, :text
      end
    end

    alter_table(:mandate) do
      if $db_type == :mysql
        set_column_type :note, :text
      end
    end

  end
end
