require 'db/migrations/utils'

Sequel.migration do

  up do

    self[:series_system_rlshp]
      .filter(:start_date => nil)
      .update(:start_date => '0000')

    alter_table(:series_system_rlshp) do
      set_column_not_null :start_date
    end

  end

  down do
  end

end
