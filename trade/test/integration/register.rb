require 'test/unit'
require 'rubygems'
require 'watir-webdriver'

class RegistrationTest < Test::Unit::TestCase

  def test_Haensel_should_register_without_image_and_interests
    b = Watir::Browser.new
    b.goto '127.0.0.1:4567/signup'
    b.text_field(:name => 'username').set 'Hänsel'
    b.text_field(:name => 'e_mail').set 'haensel@gmail.com'
    b.text_field(:name => 'password1').set 'asdf1'
    b.text_field(:name => 'password2').set 'asdf1'
    b.button(:value => 'Sign up!').click
    assert(b.text.include?("You are now registered"), "User should be able to register without image and interests")
    b.close
  end

  def test_Gretel_should_register_without_image
    b = Watir::Browser.new
    b.goto '127.0.0.1:4567/signup'
    b.text_field(:name => 'username').set 'Gretel'
    b.text_field(:name => 'e_mail').set 'gretel@gmail.com'
    b.text_field(:name => 'description').set 'cooking, cleaning and shopping'
    b.text_field(:name => 'password1').set 'asdf1'
    b.text_field(:name => 'password2').set 'asdf1'
    b.button(:value => 'Sign up!').click
    assert(b.text.include?("You are now registered"), "User should be able to register without image")
    b.close
  end
end