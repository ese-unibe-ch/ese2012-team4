require 'test/unit'
require '../../trade/app/models/item'
require '../../trade/app/models/user'

class ItemTest < Test::Unit::TestCase

  # Fake test
  def test_item_create_by_user
    owner = Trading::User.created( "testuser", "password" )
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

  #test if item is initialized correctly
  def test_item_initialisation
    owner = Trading::User.created( "testuser", "password" )
    item = owner.create_item("testobject", 50)
    assert(item.get_name == "testobject", "Name should be returned")
    assert(item.get_price == 50, "Should return price")
    assert(!item.is_active?, "Should not be active")
  end

  #test for item activation
  def test_item_activation
    owner = Trading::User.created( "testuser", "password" )
    item = owner.create_item("testobject", 50)
    assert(item.get_name == "testobject", "Name should be returned")
    assert(item.get_price == 50, "Should return price")
    assert(!item.is_active?, "Should not be active")
    item.to_active
    assert(item.get_name == "testobject", "Name should be returned")
    assert(item.get_price == 50, "Should return price")
    assert(item.is_active?, "Should be active now")
  end

  # test for items owner
  def test_item_owner
    owner = Trading::User.created( "testuser", "password" )
    item = owner.create_item("testobject", 50)
    assert(item.get_owner == owner, "Owner not set correctly")
    assert(item.get_owner.get_name == "testuser", "Owner not set correctly")
  end

  # test for items owner after selling
  def test_item_owner_after_selling
    old_owner = Trading::User.created("Old", "password")
    new_owner = Trading::User.created("New", "password")
    item = old_owner.create_item("sock",10)
    assert(item.get_owner == old_owner, "Owner not set correctly")
    assert(item.get_owner.get_name == "Old", "Owner not set correctly")
    old_owner.list_items_inactive[0].to_active
    if new_owner.buy_new_item?(item)
      old_owner.remove_item(item)
    end
    assert(item.get_owner == new_owner, "Owner not set correctly")
    assert(item.get_owner.get_name == "New", "Owner not set correctly")
  end

end