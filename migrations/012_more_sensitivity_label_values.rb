require 'db/migrations/utils'

Sequel.migration do

  up do
    enum_2_id = self[:enumeration].filter(:name => 'user_defined_enum_2').get(:id)

    [
     'distressing',
     'atsi_cultural',
    ].each_with_index do |val, ix|
      self[:enumeration_value].insert({:enumeration_id => enum_2_id, :value => val, :position => ix+3})
    end
  end

  down do
  end

end
