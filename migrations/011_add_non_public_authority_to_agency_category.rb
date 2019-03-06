require 'db/migrations/utils'

Sequel.migration do

  up do

    enum_id = self[:enumeration].filter(:name => 'agency_category').first[:id]
    position = self[:enumeration_value]
      .filter(:enumeration_id => enum_id)
      .select(Sequel.function(:max, :position).as(:position)).first[:position]

    self[:enumeration_value].insert({
                                      :enumeration_id => enum_id,
                                      :position => position + 1,
                                      :value => 'NPA',
                                    })
  end

  down do
  end

end
