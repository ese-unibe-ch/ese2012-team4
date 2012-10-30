require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative('../app/models/utility/time_handler')

include Models

class TimeHandlerTest < Test::Unit::TestCase
  def test_valid_time
    assert(TimeHandler.validTime?("20.5.2010", "19:00"))
    assert(TimeHandler.validTime?("10-5-1980"," 22:00 "))
    assert(TimeHandler.validTime?("10-12-12", "00:15"))
    assert(!TimeHandler.validTime?("aber blub", "fdjalk"))
  end

  def test_parse_time
    assert(TimeHandler.parseTime("20.5.2010", "19:00").eql?(Time.local(2010, "may", 20, 19, 0, 0)))
    assert(TimeHandler.parseTime("10-5-1980"," 22:00 ").eql?(Time.local(1980, "may", 10, 22, 0, 0)))
    assert(TimeHandler.parseTime("04-12-1", "00:15").eql?(Time.local(2004, "dec", 1, 00, 15, 0)))
  end
end