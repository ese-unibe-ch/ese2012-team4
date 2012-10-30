require 'test/unit'
require 'rubygems'
require 'watir-webdriver'

class ItemTransaction < Test::Unit::TestCase

  def test_system_should_lock_item_after_modification
    b = Watir::Browser.new
    b.goto '127.0.0.1:4567/login'
    b.text_field(:name => 'username').set 'ese'
    b.text_field(:name => 'password').set 'ese'
    b.button(:value => 'Login').click
    assert(b.text.include?("logged in"), "User should be logged in")
    b.goto '127.0.0.1:4567/home/new'
    b.text_field(:name => 'name').set 'myItem'
    b.text_field(:name => 'price').set '1'
    b.text_field(:name => 'quantity').set '20'
    b.button(:value => 'Create').click
    assert(b.text.include?("created"), "Item should be created")
    b.button(:value => 'Set active').click
    b.button(:value => 'Set Active').click
    assert(b.text.include?("activated"), "Item should be activated")
    
    c = Watir::Browser.new
    c.goto '127.0.0.1:4567/login'
    c.text_field(:name => 'username').set 'userA'
    c.text_field(:name => 'password').set 'passwordA'
    c.button(:value => 'Login').click
    assert(c.text.include?("You are now logged in"), "User should be logged in")
    c.goto '127.0.0.1:4567/users/4/1' #open ese's page

    b.button(:value => 'Set inactive').click
    assert(b.text.include?("deactivated"), "Item should be deactivated")
    b.button(:value => 'Edit').click
    b.text_field(:name => 'quantity').set '10'
    b.button(:value => 'Save changes').click
    assert(b.text.include?("changed"), "Item should be changed")
    b.button(:value => 'Set active').click
    b.button(:value => 'Set Active').click
    assert(b.text.include?("activated"), "Item should be re-activated")

    c.button(:value => 'Buy').click
    assert(c.text.include?("has been edited"), "System should display modification")

    b.close
    c.close
  end

  def test_user_should_buy_item
    b = Watir::Browser.new
    b.goto '127.0.0.1:4567/login'
    b.text_field(:name => 'username').set 'ese'
    b.text_field(:name => 'password').set 'ese'
    b.button(:value => 'Login').click
    assert(b.text.include?("logged in"), "User should be logged in")

    b.goto 'http://127.0.0.1:4567/users/2/1'
    b.button(:value => 'Buy').click
    assert(b.text.include?("bought"), "User should have bought the item")

    b.goto 'http://127.0.0.1:4567/profile/pending'
    b.button(:value => 'Arrived').click
    assert(b.text.include?("completed"), "Transfer should be completed")

    b.radio(:name => 'rating').set
    b.button(:value => 'Save').click
    assert(b.text.include?("ese"), "Rating should be completed")

    b.close
  end
end