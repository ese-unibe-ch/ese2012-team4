require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative('../../trade/app/models/module/category')

include Models

class CategoryTest < Test::Unit::TestCase
  def setup
    @supercategory = Category.get_supercategory
  end

  def test_supercategory
    assert(@supercategory.name == "none")
    testcat = Category.new("test1")
    testcat2 = Category.new("test2")
    @supercategory.add(testcat)
    @supercategory.add(testcat2)
    assert(@supercategory.list.size == 2)
    assert(@supercategory.list.include? testcat)
  end

end