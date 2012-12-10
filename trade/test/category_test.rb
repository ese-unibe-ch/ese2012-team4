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

  def teardown
    Category.delete_all
  end

  def test_initialization
    assert(@cat1.name == "test1")
    assert(@cat1.to_s == "test1")
    assert(@cat1.get_subcategories.empty?)
  end

  def test_add
    assert(@supercategory.get_subcategories.empty?)
    @supercategory.add(@cat1)
    assert(@supercategory.get_subcategories.include?(@cat1))
    assert(@supercategory.get_subcategories.size == 1)
    @supercategory.add(@cat1)
    assert(@supercategory.get_subcategories.include?(@cat1))
    assert(@supercategory.get_subcategories.size == 1)
    @supercategory.add(@cat2)
    assert(@supercategory.get_subcategories.include?(@cat2))
    assert(@supercategory.get_subcategories.size == 2)
    cat3 = Category.new("test1")
    @supercategory.add(cat3)
    assert(!@supercategory.get_subcategories.include?(cat3), "Should not add categories with the same name as an existing one.")
    assert(@supercategory.get_subcategories.size == 2)
  end

  def test_supercategory
    assert(@supercategory.name == "No Category")
    @supercategory.add(@cat1)
    @supercategory.add(@cat2)
    assert(@supercategory.get_subcategories.size == 2)
    assert(@supercategory.get_subcategories.include? @cat1)
  end

  def test_by_name
    assert(Category.by_name("No Category") == @supercategory)
    assert(Category.by_name("test1") == nil)
    @supercategory.add(@cat1)
    assert(Category.by_name("test1") == @cat1)
    assert(Category.by_name("test2") == nil)
    @cat1.add(@cat2)
    assert(Category.by_name("test2") == @cat2)
  end

  def test_get_names
    assert(@supercategory.get_names.empty?)
    @supercategory.add(@cat1)
    assert(@supercategory.get_names.include?("test1"))
    @cat1.add(@cat2)
    assert(@cat1.get_names.include?("test2"))
    assert(@supercategory.get_names.size == 1)
  end
end