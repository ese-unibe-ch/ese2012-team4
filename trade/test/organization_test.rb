def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative('../app/models/module/user')
require_relative('../app/models/module/item')
require_relative('../app/models/module/auction')
require_relative('../app/models/module/organization')

include Models

class OrganizationTest < Test::Unit::TestCase
  def setup
    @admin = User.created( "testuser", "password", "test@mail.com" )
    @org = Organization.created( "testorganization", @admin)
  end

  def test_init
    @org.save
    assert(@org.admin_list.include?(@admin))
    assert(Trader.get_all("").include?(@org))
  end
end