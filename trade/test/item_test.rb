def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative('../app/models/module/user')
require_relative('../app/models/module/item')
require_relative('../app/models/module/comment')

include Models

class ItemTest < Test::Unit::TestCase
  # runs before each test
  def setup
    @owner = Models::User.created( "testuser", "password", "test@mail.com" )
  end

  # runs after every test
  def teardown
    @owner.delete
  end

  #test static method get item
  def test_get_item
    item1 = @owner.create_item("testobject1", 50, 1)
    item2 = Item.created("testobject2", 50, @owner, 1, "bla")
    item2.save
    item3 = @owner.create_item("testobject3", 50, 1)
    assert(Item.get_item("#{item1.id}") == item1, "get_item should return the item")
    assert(Item.get_item("#{item2.id}") == item2, "get_item should return the item")
    assert(Item.get_item("#{item1.id+2}") == item3, "get_item should return the item")
  end

  #Test static method get_all
  def test_get_all
    item1 = @owner.create_item("testobject1", 50, 1)
    item2 = Item.created("testobject2", 50, @owner, 1, "bla")
    item2.save
    item3 = @owner.create_item("testobject3", 50, 1)
    item1.active= true
    item2.active= true
    item3.active = false
    assert(Item.get_all("").include?(item1), "Active Items should be in the list")
    assert(Item.get_all("").include?(item2), "Active Items should be in the list")
    assert(!Item.get_all("").include?(item3), "Inactive Items should not be in the list")
    assert(!Item.get_all(@owner.name).include?(item1), "Items of the viewer parameter should not be in the list")
  end

  # Fake test
  def test_item_create_by_user
    assert( @owner.list_items.size == 0, "Item list length should be 0" )
    assert( @owner.list_items_inactive.size == 0, "Item list inactive length should be 0" )
    @owner.create_item("testobject", 10, 1)
    assert( @owner.list_items.size == 0, "Item list length should be 0" )
    assert( @owner.list_items_inactive.size == 1, "Item list inactive length should be 1" )
    assert( !@owner.list_items_inactive[0].is_active?, "New created item should be inactive" )
    @owner.list_items_inactive[0].active = true
    assert( @owner.list_items.size == 1, "Item list length should be 1" )
    assert( @owner.list_items_inactive.size == 0, "Item list inactive length should be 0" )
    assert( @owner.list_items[0].is_active? , "New created item should now be active" )
    assert( @owner.list_items[0].to_s, "testobject, 10" )
    assert( @owner.list_items[0].description.eql?("No description available"), "Should be mentioned that no description has been entered")
  end

  #test if item is initialized correctly
  def test_item_initialisation
    item = @owner.create_item("testobject", 50, 7, "Description-text")
    assert(item.name == "testobject", "Name should be returned")
    assert(item.price == 50, "Should return price")
    assert(!item.is_active?, "Should not be active")
    assert(item.quantity == 7, "Quantity should be returned")
    assert(item.description.eql?("Description-text"), "Description should be returned")
  end

  #test for item activation
  def test_item_activation
    item = @owner.create_item("testobject", 50, 1)
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
    item = @owner.create_item("testobject", 50, 1)
    assert(item.owner == @owner, "Owner should be set correctly")
    assert(item.owner.name == "testuser", "Ownername should be set correctly")
  end

  # test for items owner after selling
  def test_item_owner_after_selling
    old_owner = User.created("Old", "password", "test@mail.com")
    new_owner = User.created("New", "password", "test@mail.com")
    item = old_owner.create_item("sock",10, 1)
    assert(item.owner == old_owner, "Owner not set correctly")
    assert(item.owner.name == "Old", "Owner not set correctly")
    old_owner.list_items_inactive[0].active = true
    if new_owner.buy_new_item(item,1)
      old_owner.remove_item(item)
    end
    assert(item.owner == new_owner, "Owner not set correctly")
    assert(item.owner.name == "New", "Owner not set correctly")
  end

  #test for price validation
  def test_valid_price
    assert(Item.valid_integer?("10"), "10 should be a valid price")
    assert(Item.valid_integer?(10), "10 should be a valid price")
    assert(Item.valid_integer?("9876543210"), "9876543210 should be a valid price")
    assert(Item.valid_integer?(9876543210), "9876543210 should be a valid price")
    assert(!Item.valid_integer?("010"), "Strings with zeros at the beginning should not be valid, because of wrong parsing")
    # LD note: 010 (without quotes) is considered octal by ruby, and becomes 8 when converted to an Integer!
    assert(!Item.valid_integer?(""), "Empty Strings should not be valid, an Item needs a price.")
    assert(!Item.valid_integer?(" "), "Empty Strings should not be valid, an Item needs a price.")
    assert(!Item.valid_integer?("dfafd"), "Letters should not be valid prices")
    assert(!Item.valid_integer?("-"), "Operators should not be valid prices")
    assert(!Item.valid_integer?("*"), "Operators should not be valid prices")
  end

  #test for is_owner? method
  def test_is_owner
    @owner.save
    item = @owner.create_item("testobject", 50, 1)
    assert(item.is_owner?(1), "The owner should be recognized by its ID.")
    assert(!item.is_owner?(2), "Wrong IDs should not match")
    #assert(!item.is_owner?("bla%ç&#12;%(/k"), "Wrong IDs should not match")
  end

  #test for editable? method
  def test_editable
    item = @owner.create_item("testobject", 50, 5, "descr")
    item.active= true
    assert(!item.editable?, "Active Items should not be editable.")
    item.active= false
    assert(item.editable?, "Inactive Items should be editable.")
  end

  #test for edit method
  def test_edit
    item = @owner.create_item("testobject",50, 10)

    assert(item.name.eql?("testobject"), "Item should have a name")
    assert(item.price.eql?(50), "Item should have a price")
    assert(item.description.eql?("No description available"), "No description was entered")
    assert(item.quantity.eql?(10), "Quantity should be set correctly")

    item.edit("new_name",23,1,"new description")

    assert(item.name.eql?("new_name"), "Item's name should have changed")
    assert(item.price.eql?(23), "Item's price should have changed")
    assert(item.description.eql?("new description"), "Item should now have a description")
    assert(item.quantity.eql?(1), "Item's quantity should have changed")
  end

  def test_validation
    item = @owner.create_item("testobject",50, 10)
    print Item.valid_integer?(item.price)
    assert item.is_valid, item.errors
    # LD TODO: add more tests
  end

  def test_item_comment
    item = @owner.create_item('test_item', 20, 1)
    comment_author = User.created('fritz','1234a','fritz@testmail.mail')
    comment = item.comment(comment_author, "This is a comment to the item")
    assert(Comment.by_id("#{comment.id}").author.eql?(comment_author), "item not correctly saved")
    assert_not_nil(item.head_comments[0], "item should have a head comment at first place")
  end

  def test_search
    item1 = @owner.create_item('item', 20, 1, "descr")
    assert(Item.search("item").include?(item1.id), "Searching for the name should return the item-id.")
    assert(Item.search("descr").include?(item1.id), "Searching for the description should return the item-id.")
    assert(Item.search("des").include?(item1.id), "Searching for parts of the description should return the item-id.")
    item2 = @owner.create_item('bla', 20, 1)
    assert(Item.search("item bla").include?(item2.id))
    assert(Item.search("item bla").include?(item1.id))
  end
end