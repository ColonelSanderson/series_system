require 'db/migrations/utils'

Sequel.migration do

  up do
     enum_2_id = self[:enumeration].filter(:name => 'user_defined_enum_2').get(:id)

    self[:enumeration_value].filter(:enumeration_id => enum_2_id).delete

     ['published', 'cultural_sensitivity', 'secret_and_sacred'].each_with_index do |val, ix|
       self[:enumeration_value].insert({:enumeration_id => enum_2_id, :value => val, :position => ix})
     end
  end

  down do
  end

end
