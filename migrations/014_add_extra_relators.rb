require 'db/migrations/utils'

Sequel.migration do

  up do
    create_enum("series_system_administers_relator", ["administered", "is_administered_by"])
    create_enum("series_system_abolition_relator", ["abolished", "is_abolished_by"])
  end

  down do
  end

end
