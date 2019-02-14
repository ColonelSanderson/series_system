require 'db/migrations/utils'

Sequel.migration do
  up do
    self[:agent_corporate_entity].update(:system_mtime => Time.now)
  end
end
