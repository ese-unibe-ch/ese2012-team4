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
    # LD take care! This test is run last. They are run in alphabetical
    #    order, so don't rely on a specific order.
    @org.save
    assert(@org.admin_list.include?(@admin))
    assert(Trader.get_all("").include?(@org))
  end

  def test_addAdmin_deleteAdmin
    @admin2 = User.created("superuser", "password", "test2@mail.com")
    assert(!@org.can_delete_admin?)
    assert(!@org.admin_list.include?(@admin2))

    @org.add_admin(@admin2)
    assert(@org.admin_list.include?(@admin2))
    assert(@admin2.admin_of_org_list.include?(@org))

    assert(@org.can_delete_admin?)
    @org.delete_admin(@admin2)
    assert(!@org.admin_list.include?(@admin2))
    assert(!@admin2.admin_of_org_list.include?(@org))
    assert(!@org.can_delete_admin?)
  end

  def test_addMember_delete_Member
    @member = User.created("member", "password", "member@mail.com")
    assert(!@org.member_list.include?(@member))
    @org.add_member(@member)
    assert(@org.member_list.include?(@member))
    assert(@member.organization_list.include?(@org))

    @org.delete_member(@member)
    assert(!@org.member_list.include?(@member))
    assert(!@member.organization_list.include?(@org))
  end



end