require 'test/unit'
require '../../trade/app/models/item'
require '../../trade/app/models/user'

class UserTest < Test::Unit::TestCase

  # Fake test
  def test_user_item_create
    owner = Trading::User.created( "testuser" )
    assert( owner.list_items.size == 0, "Item list length should be 0" )
    assert( owner.list_items_inactive.size == 0, "Item list inactive length should be 0" )
    owner.create_item("testobject", 10)
    assert( owner.list_items.size == 0, "Item list length should be 0" )
    assert( owner.list_items_inactive.size == 1, "Item list inactive length should be 1" )
    assert( !owner.list_items_inactive[0].is_active?, "New created item should be inactive" )
    owner.list_items_inactive[0].to_active
    assert( owner.list_items.size == 1, "Item list length should be 1" )
    assert( owner.list_items_inactive.size == 0, "Item list inactive length should be 0" )
    assert( owner.list_items[0].is_active? , "New created item should now be active" )
    assert( owner.list_items[0].to_s, "testobject, 10" )
  end

  def test_create_user
    owner = Trading::User.created( "testuser" )
    assert( owner.get_name == "testuser", "Name should be correct")
    assert( owner.get_credits == 100, "Credits should be 100 first")
    assert( owner.to_s == "testuser has currently 100 credits, 0 active and 0 inactive items", "String representation is wrong generated")
  end

  def test_sales
    old_owner = Trading::User.created("Old")
    new_owner = Trading::User.created("New")

    sock = old_owner.create_item("sock",10)
    assert( !sock.is_active?, "item should not be active, is")
    assert( !old_owner.list_items_inactive[0].is_active?, "item should not be active, is")

    old_owner.list_items_inactive[0].to_active
    assert( sock.is_active?, "item should be active, is not")
    assert( old_owner.list_items[0].is_active?, "item should be active, is not")

    if new_owner.buy_new_item?(sock)
      old_owner.remove_item(sock)
    end

    assert(old_owner.list_items.size==0)
    assert(old_owner.list_items_inactive.size==0)
    assert(new_owner.list_items.size==0)
    assert(new_owner.list_items_inactive.size==1)

    assert( !sock.is_active?, "item should not be active, is")
    assert( !new_owner.list_items_inactive[0].is_active?, "item should not be active, is")

    assert(old_owner.get_credits == 110, "Seller should now have more money")
    assert(new_owner.get_credits == 90, "Buyer should now have less money")
  end

  def test_sales_not_possible_because_of_price
    old_owner = Trading::User.created("Old")
    new_owner = Trading::User.created("New")

    sock = old_owner.create_item("sock",210)
    assert( !sock.is_active?, "item should not be active, is")

    sock.to_active
    assert( sock.is_active?, "item should be active, is not")

    if new_owner.buy_new_item?(sock)
      old_owner.remove_item(sock)
    end

    assert(old_owner.list_items_inactive.size==0)
    assert(old_owner.list_items.size==1)
    assert(new_owner.list_items_inactive.size==0)
    assert(new_owner.list_items.size==0)

    assert( sock.is_active?, "item should be active, is not")

    assert(old_owner.get_credits == 100, "Money should be like before")
    assert(new_owner.get_credits == 100, "Money should be like before")
  end

  def test_method_list_active
    owner = Trading::User.created( "testuser" )
    owner.create_item("testobject", 10)
    owner.create_item("testobject2", 50)
    owner.list_items_inactive[0].to_active
    owner.list_items_inactive[0].to_active
    assert(owner.list_items[0].to_s == "testobject, 10")
    assert(owner.list_items[1].to_s == "testobject2, 50")
  end

  def test_method_list_inactive
    owner = Trading::User.created( "testuser" )
    owner.create_item("testobject", 10)
    owner.create_item("testobject2", 50)
    assert(owner.list_items_inactive[0].to_s == "testobject, 10")
    assert(owner.list_items_inactive[1].to_s == "testobject2, 50")
    owner.list_items_inactive[0].to_active
    owner.list_items_inactive[0].to_active
    assert(owner.list_items[0].to_s == "testobject, 10")
    assert(owner.list_items[1].to_s == "testobject2, 50")
    owner.list_items[0].to_inactive
    owner.list_items[0].to_inactive
    assert(owner.list_items_inactive[0].to_s == "testobject, 10")
    assert(owner.list_items_inactive[1].to_s == "testobject2, 50")
  end

end