require 'db/migrations/utils'

Sequel.migration do

  up do
#
# *** This has been moved to the as_runcorn plugin because it is a QSA specific requirement ***
#
#     enum_id = self[:enumeration].filter(:name => 'agency_category').first[:id]
#     position = self[:enumeration_value]
#       .filter(:enumeration_id => enum_id)
#       .select(Sequel.function(:max, :position).as(:position)).first[:position]

#     self[:enumeration_value].insert({
#                                       :enumeration_id => enum_id,
#                                       :position => position + 1,
#                                       :value => 'NPA',
#                                     })
  end

  down do
  end

end
