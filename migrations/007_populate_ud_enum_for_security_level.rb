require 'db/migrations/utils'

Sequel.migration do

  up do
    enum_1_id = self[:enumeration].filter(:name => 'user_defined_enum_1').get(:id)

    self[:enumeration_value].filter(:enumeration_id => enum_1_id).delete

    ['official', 'sensitive', 'protected'].each_with_index do |val, ix|
      self[:enumeration_value].insert({:enumeration_id => enum_1_id, :value => val, :position => ix})
    end
  end

  down do
  end

end
