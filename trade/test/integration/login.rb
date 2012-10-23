require 'test/unit'
require 'rubygems'
require 'watir-webdriver'

class LoginTest < Test::Unit::TestCase
  def test_ESE_should_log_in
    b = Watir::Browser.new
    b.goto '127.0.0.1:4567/login'
    b.text_field(:name => 'username').set 'ese'
    b.text_field(:name => 'password').set 'ese'
    b.button(:value => 'Login').click
    assert(b.text.include?("You are now logged in"), "User should be loggedd in")
    b.close
  end
end