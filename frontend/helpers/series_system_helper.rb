module SeriesSystemHelper

  def self.supports_mandate?(jsonmodel)
    ['resource', 'archival_object', 'agent_corporate_entity'].include?(jsonmodel)
  end

  def self.supports_function?(jsonmodel)
    ['resource', 'archival_object'].include?(jsonmodel)
  end

end