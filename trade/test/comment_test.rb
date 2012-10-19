require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative('../app/models/module/user')
require_relative('../app/models/module/item')
require_relative('../app/models/module/comment')

include Models

class MyTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @author = User.created("testuser", "1234a", "test@mail.com")
    @item = @author.create_item("chair", 34, 1)
  end

  def test_initialization
    assert(@author.name.eql?("testuser"), "wrong name")

    comment = Comment.created(@author, @item, 'Hello, this is a test comment')

    assert_not_nil(comment)
    assert(comment.id.eql?(1), "wrong id")
    assert(comment.author.eql?(@author), "wrong author")
    assert(comment.correspondent_item.eql?(@item), "wrong correspondant item")
    assert_nil(comment.previous_comment)
  end

  def test_is_head_comment
    comment = Comment.created(@author, @item, 'test comment')
    assert(comment.is_head_comment?, "should be a head comment")
  end
end