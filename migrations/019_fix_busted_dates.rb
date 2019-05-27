require 'db/migrations/utils'
require 'date'

Sequel.migration do

  up do
    fix_date = proc {|date_str|
      if date_str.nil?
        nil
      else
        date_str.split('-').take(3).map {|s| sprintf('%2s', s).gsub(' ', '0') }.join('-')
      end
    }


    self.transaction do
      self["select id from date " +
           " where (begin is not null AND begin not regexp '^[0-9]{4}(-[0-9]{2})?(-[0-9]{2})?$')" +
           "  OR (end is not null AND end not regexp '^[0-9]{4}(-[0-9]{2})?(-[0-9]{2})?$')"].each do |row|
        busted_row = self[:date][:id => row[:id]]

        self[:date].filter(:id => row[:id]).update(:begin => fix_date.call(busted_row[:begin]),
                                                   :end => fix_date.call(busted_row[:end]))
      end

      self["select id from series_system_rlshp " +
           " where (start_date is not null AND start_date not regexp '^[0-9]{4}(-[0-9]{2})?(-[0-9]{2})?$')" +
           "  OR (end_date is not null AND end_date not regexp '^[0-9]{4}(-[0-9]{2})?(-[0-9]{2})?$')"].each do |row|
        busted_row = self[:series_system_rlshp][:id => row[:id]]

        self[:series_system_rlshp].filter(:id => row[:id]).update(:start_date => fix_date.call(busted_row[:start_date]),
                                                                  :end_date => fix_date.call(busted_row[:end_date]))
      end

    end
  end

  down do
  end

end
