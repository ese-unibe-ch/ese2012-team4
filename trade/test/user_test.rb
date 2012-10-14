def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative('../app/models/module/user')
require_relative('../app/models/module/item')

class UserTest < Test::Unit::TestCase

  # Fake test
  def test_user_item_create
    owner = Models::User.created( "testuser", "password" )
    assert( owner.list_items.size == 0, "Item list length should be 0" )
    assert( owner.list_items_inactive.size == 0, "Item list inactive length should be 0" )
    owner.create_item("testobject", 10, 1)
    assert( owner.list_items.size == 0, "Item list length should be 0" )
    assert( owner.list_items_inactive.size == 1, "Item list inactive length should be 1" )
    assert( !owner.list_items_inactive[0].is_active?, "New created item should be inactive" )
    owner.list_items_inactive[0].active = true
    assert( owner.list_items.size == 1, "Item list length should be 1" )
    assert( owner.list_items_inactive.size == 0, "Item list inactive length should be 0" )
    assert( owner.list_items[0].is_active? , "New created item should now be active" )
    assert( owner.list_items[0].to_s, "testobject, 10" )
  end

  def test_create_user
    owner = Models::User.created( "testuser", "password" )
    assert( owner.name == "testuser", "Name should be correct")
    assert( owner.credits == 100, "Credits should be 100 first")
    assert( owner.to_s == "testuser has currently 100 credits, 0 active and 0 inactive items", "String representation is wrong generated")
  end

  def test_sales
    old_owner = Models::User.created("Old", "password")
    new_owner = Models::User.created("New", "password")

    sock = old_owner.create_item("sock",10, 1)
    assert( !sock.is_active?, "item should not be active, is")
    assert( !old_owner.list_items_inactive[0].is_active?, "item should not be active, is")

    old_owner.list_items_inactive[0].active = true
    assert( sock.is_active?, "item should be active, is not")
    assert( old_owner.list_items[0].is_active?, "item should be active, is not")

    if new_owner.buy_new_item?(sock, 1)
      old_owner.remove_item(sock)
    end

    assert(old_owner.list_items.size==0)
    assert(old_owner.list_items_inactive.size==0)
    assert(new_owner.list_items.size==0)
    assert(new_owner.list_items_inactive.size==1)

    assert( !sock.is_active?, "item should not be active, is")
    assert( !new_owner.list_items_inactive[0].is_active?, "item should not be active, is")

    assert(old_owner.credits == 110, "Seller should now have more money")
    assert(new_owner.credits == 90, "Buyer should now have less money")
  end

  def test_sales_not_possible_because_of_price
    old_owner = Models::User.created("Old", "password")
    new_owner = Models::User.created("New", "password")

    sock = old_owner.create_item("sock",210,1)
    assert( !sock.is_active?, "item should not be active, is")

    sock.active = true
    assert( sock.is_active?, "item should be active, is not")

    if new_owner.buy_new_item?(sock, 1)
      old_owner.remove_item(sock)
    end

    assert(old_owner.list_items_inactive.size==0)
    assert(old_owner.list_items.size==1)
    assert(new_owner.list_items_inactive.size==0)
    assert(new_owner.list_items.size==0)

    assert( sock.is_active?, "item should be active, is not")

    assert(old_owner.credits == 100, "Money should be like before")
    assert(new_owner.credits == 100, "Money should be like before")
  end

  def test_method_list_active
    owner = Models::User.created( "testuser", "password" )
    owner.create_item("testobject", 10, 1)
    owner.create_item("testobject2", 50, 1)
    owner.list_items_inactive[0].active = true
    owner.list_items_inactive[0].active = true
    assert(owner.list_items[0].to_s == "testobject, 10")
    assert(owner.list_items[1].to_s == "testobject2, 50")
  end

  def test_method_list_inactive
    owner = Models::User.created( "testuser", "password" )
    owner.create_item("testobject", 10, 1)
    owner.create_item("testobject2", 50, 1)
    assert(owner.list_items_inactive[0].to_s == "testobject, 10")
    assert(owner.list_items_inactive[1].to_s == "testobject2, 50")
    owner.list_items_inactive[0].active = true
    owner.list_items_inactive[0].active = true
    assert(owner.list_items[0].to_s == "testobject, 10")
    assert(owner.list_items[1].to_s == "testobject2, 50")
    owner.list_items[0].active = false
    owner.list_items[0].active = false
    assert(owner.list_items_inactive[0].to_s == "testobject, 10")
    assert(owner.list_items_inactive[1].to_s == "testobject2, 50")
  end

  def test_auth
    owner = Models::User.created( "testuser", "password" )
    assert (Models::User.login "testuser", "password")
  end

  def test_available
    oldUser = Models::User.created( "Mike", "234")
    assert (oldUser.name == "Mike")
    oldUser.save
    assert (!Models::User.available? "Mike")
  end

  def test_delete
    testUser = Models::User.created( "Mike", "234")
    assert (!Models::User.available? "Mike")
    testUser.delete
    assert (Models::User.available? "Mike")

  end

end