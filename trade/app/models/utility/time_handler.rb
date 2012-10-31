require 'date'
require 'time'

module Models

  # The TimeHandler handles parsing of String- to Time-Objects
  class TimeHandler

    # Checks if a date and a time String are valid for parsing to a Time object
    # - @param [String] date
    # - @param [String] time
    # - @return true, if the date and time are parseable. Take care of different notations, because they might be parsed differently.
    def self.validTime?(date, time)
      if(date.eql?("") and time.eql?(""))
        return true
      end
      begin
        # With DateTime.parse Errors are raised if it fails to parse, other than with Time.parse
        DateTime.parse(date+ " " +time)
        return true
      rescue  ArgumentError
        return false
      end
    end

    # Parses a String to a Time object
    # Invalid Strings will return the actual time.
    def self.parseTime(date, time)
      Time.parse(date+ " " + time)
    end
  end
end
