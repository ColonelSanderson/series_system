require 'db/migrations/utils'

Sequel.migration do

  up do

    alter_table(:series_system_rlshp) do
      add_column(:suppressed, :integer, :null => false, :default => 0)
    end

  end

  down do
  end

end
