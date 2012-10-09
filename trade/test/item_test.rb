def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative('../app/models/module/user')
require_relative('../app/models/module/item')

include Models

class ItemTest < Test::Unit::TestCase

  #test static method get item
  def test_get_item
    owner = User.created( "testuser", "password" )
    item1 = owner.create_item("testobject1", 50)
    item2 = Item.created("testobject2", 50, owner, "bla")
    item2.save
    item3 = owner.create_item("testobject2", 50)
    assert(Item.get_item("#{item1.id}") == item1, "get_item should return the item")
    assert(Item.get_item("#{item2.id}") == item2, "get_item should return the item")
    assert(Item.get_item("#{item1.id+2}") == item3, "get_item should return the item")
  end

  #Test static method get_all
  def test_get_all
    owner = User.created( "testuser", "password" )
    item1 = owner.create_item("testobject1", 50)
    item2 = Item.created("testobject2", 50, owner, "bla")
    item2.save
    item3 = owner.create_item("testobject2", 50)
    item1.active= true
    item2.active= true
    item3.active = false
    assert(Item.get_all("").include?(item1), "Active Items should be in the list")
    assert(Item.get_all("").include?(item2), "Active Items should be in the list")
    assert(!Item.get_all("").include?(item3), "Inactive Items should not be in the list")
    assert(!Item.get_all(owner.name).include?(item1), "Items of the viewer parameter should not be in the list")
  end

  # Fake test
  def test_item_create_by_user
    owner = User.created( "testuser", "password" )
    assert( owner.list_items.size == 0, "Item list length should be 0" )
    assert( owner.list_items_inactive.size == 0, "Item list inactive length should be 0" )
    owner.create_item("testobject", 10)
    assert( owner.list_items.size == 0, "Item list length should be 0" )
    assert( owner.list_items_inactive.size == 1, "Item list inactive length should be 1" )
    assert( !owner.list_items_inactive[0].is_active?, "New created item should be inactive" )
    owner.list_items_inactive[0].active = true
    assert( owner.list_items.size == 1, "Item list length should be 1" )
    assert( owner.list_items_inactive.size == 0, "Item list inactive length should be 0" )
    assert( owner.list_items[0].is_active? , "New created item should now be active" )
    assert( owner.list_items[0].to_s, "testobject, 10" )
    assert( owner.list_items[0].description.eql?("No description available"), "Should be mentioned that no description has been entered")
  end

  #test if item is initialized correctly
  def test_item_initialisation
    owner = User.created( "testuser", "password" )
    item = owner.create_item("testobject", 50, "Description-text")
    assert(item.name == "testobject", "Name should be returned")
    assert(item.price == 50, "Should return price")
    assert(!item.is_active?, "Should not be active")
    assert(item.description.eql?("Description-text"), "Description should be returned")
  end

  #test for item activation
  def test_item_activation
    owner = User.created( "testuser", "password" )
    item = owner.create_item("testobject", 50)
    assert(item.name == "testobject", "Name should be returned")
    assert(item.price == 50, "Should return price")
    assert(!item.is_active?, "Should not be active")
    item.active = true
    assert(item.name == "testobject", "Name should be returned")
    assert(item.price == 50, "Should return price")
    assert(item.is_active?, "Should be active now")
  end

  # test for items owner
  def test_item_owner
    owner = User.created( "testuser", "password" )
    item = owner.create_item("testobject", 50)
    assert(item.owner == owner, "Owner not set correctly")
    assert(item.owner.name == "testuser", "Owner not set correctly")
  end

  # test for items owner after selling
  def test_item_owner_after_selling
    old_owner = User.created("Old", "password")
    new_owner = User.created("New", "password")
    item = old_owner.create_item("sock",10)
    assert(item.owner == old_owner, "Owner not set correctly")
    assert(item.owner.name == "Old", "Owner not set correctly")
    old_owner.list_items_inactive[0].active = true
    if new_owner.buy_new_item?(item)
      old_owner.remove_item(item)
    end
    assert(item.owner == new_owner, "Owner not set correctly")
    assert(item.owner.name == "New", "Owner not set correctly")
  end

  #test for price validation
  def test_valid_price
    assert(Item.valid_price?("10"), "10 should be a valid price")
    assert(Item.valid_price?("9876543210"), "9876543210 should be a valid price")
    assert(!Item.valid_price?("010"), "Strings with zeros at the beginning should not be valid, because of wrong parsing")
    assert(!Item.valid_price?(""), "Empty Strings should not be valid, an Item needs a price.")
    assert(!Item.valid_price?(" "), "Empty Strings should not be valid, an Item needs a price.")
    assert(!Item.valid_price?("dfafd"), "Letters should not be valid prices")
    assert(!Item.valid_price?("-"), "Operators should not be valid prices")
    assert(!Item.valid_price?("*"), "Operators should not be valid prices")
  end

  #test for is_owner? method
  def test_is_owner
    owner = User.created( "testuser", "password" ).save
    item = owner.create_item("testobject", 50)
    assert(item.is_owner?("testuser"), "The owner should be recognized by its name.")
    assert(!item.is_owner?("testuser   "), "Wrong names should not match")
    assert(!item.is_owner?("bla%ç&%(/"), "Wrong names should not match")
  end

  #test for editable? method
  def test_editable
    owner = User.created( "testuser", "password" )
    item = owner.create_item("testobject", 50, "descr")
    item.active= true
    assert(!item.editable?, "Active Items should not be editable.")
    item.active= false
    assert(item.editable?, "Inactive Items should be editable.")
  end

end