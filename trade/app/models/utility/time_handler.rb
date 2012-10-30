require 'date'
require 'time'

module Models

  class TimeHandler

    #Checks if a date and a time String are valid for a Time object
    def self.validTime?(date, time)
      if(date.eql?("") and time.eql?(""))
        return true
      end
      begin
        DateTime.parse(date+ " " +time)
        return true
      rescue  ArgumentError
        return false
      end
    end

    #Parses a String to a Time object
    #Invalid Strings will return the actual time.
    def self.parseTime(date, time)
      Time.parse(date+ " " + time)
    end


  end
end
