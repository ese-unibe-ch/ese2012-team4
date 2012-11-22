require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative('../app/models/module/user')
require_relative('../app/models/module/item')
require_relative('../app/models/module/organization')
require_relative('../app/models/module/activity')

include Models

class ActivityTest < Test::Unit::TestCase
  def setup
    User.clear_all
    @admin = User.created( "testuser", "password", "test@mail.com" )
    @org = Organization.created( "testorganization", @admin)
    @userA = User.created("Hans", "hansli", "bla@mail.com")
    @userB = User.created("Horst", "horstli", "bla1@mail.com")
    @userC = User.created("Vreni", "vreneli", "bla2@mail.com")
    @userD = User.created("Penner", "pennerli", "bla3@mail.com")
    @userA.credits = 1000
    @userB.credits = 1000
    @userC.credits = 1000
    @userD.credits = 10
    @org.add_member(@userA)
    @org.add_member(@userB)
    @org.add_member(@userC)
    @userA.working_for = @org
    @userB.working_for = @org
    @userC.working_for = @org
  end

  def teardown
    User.clear_all
  end

  def test_add_item
    item = @userA.create_item('item', 20, 2, "descr")
    assert @org.activities.size == 1
    assert @org.activities[0].to_s == "Hans added 'item' for a price of 20 credits"
    item2 = @userD.create_item('item2', 20, 2, "descr")
    assert @org.activities.size == 1
    item3 = @userB.create_item('item3', 20, 2, "descr")
    assert @org.activities.size == 2
    assert @org.activities[1].to_s == "Horst added 'item3' for a price of 20 credits"
  end

  def test_edit_item
    item = @userA.create_item('item', 20, 2, "descr")
    assert @org.activities.size == 1
    @userA.edit_item(item, 'item', 30, 2,  "descr")
    assert @org.activities.size == 2
    assert @org.activities[1].to_s == "Hans edited 'item'"
  end

  def test_activate_deactivate_item
    item = @userC.create_item('item', 20, 2, "descr")
    assert @org.activities.size == 1
    @userC.activate_item(item.id.to_s)
    assert @org.activities.size == 2
    assert @org.activities[1].to_s == "Vreni activated 'item'"
    @userC.deactivate_item(item.id.to_s)
    assert @org.activities.size == 3
    assert @org.activities[2].to_s == "Vreni deactivated 'item'"
  end

  def test_comment
    item = @userC.create_item('item', 20, 2, "descr")
    assert @org.activities.size == 1
    @userC.activate_item(item.id)
    assert @org.activities.size == 2
    @userD.comment_item(item, "Awesome shit!")
    # this fails because item belongs to @userC, although it was created
    # in the context of @org
    assert @org.activities.size == 3
    assert @org.activities[2].to_s == "Penner commented on 'item'"
  end

  def test_item_sold
    item = @userC.create_item('item', 5, 2, "descr")
    assert @org.activities.size == 1
    @userC.activate_item(item.id)
    assert @org.activities.size == 2
    @userD.buy_new_item(item, 1)
    assert @org.activities.size == 3
    assert @org.activities[2].to_s == "'item' was bought by Penner for 5 credits"
  end

  def test_item_not_sold
    fail
  end

  def test_item_bought
    item = @userD.create_item('item', 5, 2, "descr")
    @userD.activate_item(item.id)
    @userB.buy_new_item(item, 1)
    assert @org.activities.size == 1
    assert @org.activities[0].to_s == "Horst has bought 'item' for 5 credits"
  end

  def test_item_not_bought
    fail
  end
end