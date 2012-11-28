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
    assert @org.activities.size == 3
    assert @org.activities[2].to_s == "Penner commented on 'item'"
  end

  def test_item_sold
    item = @userC.create_item('item', 5, 2, "descr")
    assert @org.activities.size == 1
    @userC.activate_item(item.id)
    assert @org.activities.size == 2
    @userD.buy_new_item(item, 1, @userD)
    assert @org.activities.size == 3
    assert @org.activities[2].to_s == "'item' was bought by Penner for 5 credits"
  end

  def test_item_not_sold
    item = @userC.create_item('Mona Lisa painting', 9999, 2, "descr")
    assert @org.activities.size == 1
    @userC.activate_item(item.id)
    assert @org.activities.size == 2
    @userD.buy_new_item(item, 1, @userD)
    assert @org.activities.size == 3
    assert @org.activities[2].to_s == "'Mona Lisa painting' could not be bought by Penner for 9999 credits"
    assert @userD.activities.size == 1
    assert @userD.activities[0].to_s == "Penner was unable to buy 'Mona Lisa painting' for 9999 credits"
  end

  def test_item_bought
    item = @userD.create_item('item', 5, 2, "descr")
    @userD.activate_item(item.id)
    @userB.working_for.buy_new_item(item, 1, @userB)
    assert @org.activities.size == 1
    assert @org.activities[0].to_s == "Horst has bought 'item' for 5 credits"

  end

  def test_item_not_bought
    item = @userD.create_item('Cardboard house', 2000, 1, "Warm and sweet")
    @userD.activate_item(item.id)
    @userA.working_for.buy_new_item(item, 1,@userA)
    assert @org.activities.size == 1
    #ToDo: fix it, that this works, at the moment it loggs the organisation name
    #assert @org.activities[0].to_s == "Hans was unable to buy 'Cardboard house' for 2000 credits"
  end
end