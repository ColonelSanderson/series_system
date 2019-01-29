module SeriesSystemHelper

  def self.supports_mandate?(jsonmodel)
    ['resource', 'archival_object', 'agent_corporate_entity'].include?(jsonmodel)
  end

  def self.supports_function?(jsonmodel)
    ['resource', 'archival_object', 'agent_corporate_entity'].include?(jsonmodel)
  end

  def self.date_display_string(date)
    return "" if date.nil? 

    if date['expression']
      date['expression']
    elsif date['begin'] || date['end']
      "#{date['begin']} - #{date['end']}"
    else
      ""
    end
  end
end