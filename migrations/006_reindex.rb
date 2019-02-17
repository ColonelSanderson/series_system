require 'db/migrations/utils'

Sequel.migration do
  up do
    self[:agent_corporate_entity].update(:system_mtime => Time.now)
    self[:function].update(:system_mtime => Time.now)
    self[:mandate].update(:system_mtime => Time.now)
    self[:resource].update(:system_mtime => Time.now)
    self[:archival_object].update(:system_mtime => Time.now)
  end
end
