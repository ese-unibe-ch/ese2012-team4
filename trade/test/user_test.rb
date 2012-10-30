def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative('../app/models/module/user')
require_relative('../app/models/module/item')

class UserTest < Test::Unit::TestCase
  # runs before each test
  def setup
    @owner = Models::User.created( "testuser", "password", "test@mail.com" )
  end

  # runs after every test
  def teardown
    @owner.delete
  end

  def test_activate_item
    item = @owner.create_item("testobject", 5, 2)
    assert(!item.is_active?)
    @owner.activate_item("#{item.id}")
    assert(item.is_active?)

    more_of_same_item = @owner.create_item("testobject", 5, 2)
    assert(!more_of_same_item.is_active?)
    @owner.activate_item("#{more_of_same_item.id}")
    assert(item.quantity.eql?(4))
  end

  def test_deactivate_item
    item = @owner.create_item("testobject", 5, 2)
    @owner.activate_item("#{item.id}")
    assert(item.is_active?)

    user1 = Models::User.created("user1", "password1", "user1@mail.com")
    user1.add_to_wishlist(item)
    assert(user1.wishlist.include?(item))

    @owner.deactivate_item("#{item.id}")
    assert(!item.is_active?)
    assert(!user1.wishlist.include?(item))
  end

  def test_get_all
    user1 = Models::User.created("user1", "password1", "user1@mail.com")
    user1.save

    user2 = Models::User.created("user2", "password2", "user2@mail.com")
    user2.save

    assert(Models::User.get_all(user1).include?(user2))
    assert(!Models::User.get_all(user1).include?(user1))
  end
  # Fake test
  def test_user_item_create
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
  end

  def test_create_user
    assert( @owner.name == "testuser", "Name should be correct")
    assert( @owner.credits == 100, "Credits should be 100 first")
    assert( @owner.to_s == "testuser has currently 100 credits, 0 active and 0 inactive items", "String representation is wrong generated")
  end

  def test_sales
    old_owner = Models::User.created("Old", "password", "test@mail.com")
    new_owner = Models::User.created("New", "password", "test@mail.com")

    sock = old_owner.create_item("sock",10, 1)
    assert( !sock.is_active?, "item should not be active, is")
    assert( !old_owner.list_items_inactive[0].is_active?, "item should not be active, is")

    old_owner.list_items_inactive[0].active = true
    assert( sock.is_active?, "item should be active, is not")
    assert( old_owner.list_items[0].is_active?, "item should be active, is not")

    if new_owner.buy_new_item(sock, 1)
      old_owner.remove_item(sock)
    end

    assert old_owner.list_items.size == 0
    assert old_owner.list_items_inactive.size == 0
    assert new_owner.list_items.size == 0
    assert new_owner.list_items_inactive.size == 0

    pending = Models::Holding.get_all.last
    assert pending.item == sock
    assert pending.seller == old_owner
    assert pending.buyer == new_owner

    pending.itemReceived

    assert old_owner.list_items.size == 0
    assert old_owner.list_items_inactive.size == 0
    assert new_owner.list_items.size == 0
    assert new_owner.list_items_inactive.size == 1

    assert( !sock.is_active?, "item should not be active, is")
    assert( !new_owner.list_items_inactive[0].is_active?, "item should not be active, is")

    assert(old_owner.credits == 110, "Seller should now have more money")
    assert(new_owner.credits == 90, "Buyer should now have less money")
  end

  def test_sales_not_possible_because_of_price
    old_owner = Models::User.created("Old", "password", "test@mail.com")
    new_owner = Models::User.created("New", "password", "test@mail.com")

    sock = old_owner.create_item("sock",210,1)
    assert( !sock.is_active?, "item should not be active, is")

    sock.active = true
    assert( sock.is_active?, "item should be active, is not")

    if new_owner.buy_new_item(sock, 1)
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
    @owner.create_item("testobject", 10, 1)
    @owner.create_item("testobject2", 50, 1)
    @owner.list_items_inactive[0].active = true
    @owner.list_items_inactive[0].active = true
    assert(@owner.list_items[0].to_s == "testobject, 10")
    assert(@owner.list_items[1].to_s == "testobject2, 50")
  end

  def test_method_list_inactive
    @owner.create_item("testobject", 10, 1)
    @owner.create_item("testobject2", 50, 1)
    assert(@owner.list_items_inactive[0].to_s == "testobject, 10")
    assert(@owner.list_items_inactive[1].to_s == "testobject2, 50")
    @owner.list_items_inactive[0].active = true
    @owner.list_items_inactive[0].active = true
    assert(@owner.list_items_inactive.empty? == true)
    assert(@owner.list_items[0].to_s == "testobject, 10")
    assert(@owner.list_items[1].to_s == "testobject2, 50")
    @owner.list_items[0].active = false
    @owner.list_items[0].active = false
    assert(@owner.list_items_inactive[0].to_s == "testobject, 10")
    assert(@owner.list_items_inactive[1].to_s == "testobject2, 50")
  end

  def test_auth
    @owner.save
    assert (Models::User.login @owner.id, "password")
  end

  def test_available
    assert (@owner.name == "testuser")
    assert (Models::User.available? "testuser")
    @owner.save
    assert (!Models::User.available? "testuser")
  end

  def test_delete
    @owner.save
    assert (!Models::User.available? "testuser")
    @owner.delete
    assert (Models::User.available? "testuser")
  end

  def test_validation
    assert @owner.is_valid
  end

  def test_validation_duplicate_username
    @owner.save
    user1 = Models::User.created( "testuser", "password", "test@mail.com" )
    assert !user1.is_valid
  end

  def test_validation_missing_name_e_mail
    user1 = Models::User.created( "", "password", "test@mail.com" )
    assert !user1.is_valid
    user2 = Models::User.created( "testuser", "password", "" )
    assert !user2.is_valid
    user3 = Models::User.created( "testuser", "password", "testmail.com" )
    assert !user3.is_valid
    user4 = Models::User.created( "testuser", "password", "test@mailcom" )
    assert !user4.is_valid
  end

  def test_validation_password
    assert @owner.is_valid("asdfasdf1", "asdfasdf1")
    assert !@owner.is_valid("asdfasdf1", "asdfasdf")
    assert !@owner.is_valid("asdfasdf", "asdfasdf")
    assert !@owner.is_valid("asdfasdf1", "")
    assert !@owner.is_valid("", "asdfasdf1")
    assert !@owner.is_valid("asdf", "asdf")
    assert @owner.is_valid("aSdfasdf1", "aSdfasdf1")
  end

  def test_wishlist
    user1 = Models::User.created( "testuser1", "password", "test@mail.com" )
    item1 = user1.create_item("testobject", 10, 1)
    id_before = item1.id
    item2 = user1.create_item("testobject2", 50, 1)
    user2 = Models::User.created( "testuser2", "password", "test@mail.com" )
    assert item1.owner.name == user1.name
    assert user2.wishlist.size == 0
    assert item1.wishlist_users.size == 0
    assert item2.wishlist_users.size == 0
    user2.add_to_wishlist(item1)
    assert item1.owner.eql?(user1)
    assert item1.id == id_before
    item1.active = true
    assert user2.wishlist.size == 1
    assert item1.wishlist_users.size == 1
    assert item2.wishlist_users.size == 0
    assert item1.owner.name == user1.name
  end

end