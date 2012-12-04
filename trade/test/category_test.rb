require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative('../app/models/module/category')
require_relative('../app/models/module/offer')
require_relative('../app/models/module/trader')
require_relative('../app/models/module/user')
require_relative('../app/models/module/item')

include Models

class CategoryTest < Test::Unit::TestCase
  def setup
    @supercategory = Category.get_supercategory
    @cat1 = Category.new("test1")
    @cat2 = Category.new("test2")
    @owner = Models::User.created( "testuser", "password", "test@mail.com" )
    @testitem = Item.created("test", 10, @owner, 1)
    @testitem.save
  end

  def test_supercategory
    assert(@supercategory.name == "No Category")
    @supercategory.add(@cat1)
    @supercategory.add(@cat2)
    assert(@supercategory.get_subcategories.size == 2)
    assert(@supercategory.get_subcategories.include? @cat1)
    assert(@supercategory.get_offers.include?(@testitem))
  end

  def test_initialization
    assert(@cat1.name == "test1")
    assert(@cat1.to_s == "test1")
    assert(@cat1.get_subcategories.empty?)
  end

  def test_get_offers
    @testitem.category = @cat1
    assert(@cat1.get_offers.include?@testitem)
    testitem2 = Item.created("test2", 10, @owner, 1)
    testitem2.category = @cat2
    testitem2.save
    @cat1.add(@cat2)
    assert(@cat2.get_offers.include? testitem2)
    assert(@cat1.get_offers.include?testitem2)
    assert(@cat1.get_offers.include?@testitem)

  end

end