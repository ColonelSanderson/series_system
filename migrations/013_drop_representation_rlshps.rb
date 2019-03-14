require 'db/migrations/utils'

Sequel.migration do

  up do
    self[:series_system_rlshp].filter(Sequel.like(:jsonmodel_type, '%representation%')).delete
  end

  down do
  end

end
