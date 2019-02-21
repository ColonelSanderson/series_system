module SeriesSystemHelper

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