require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative('../app/models/module/user')
require_relative('../app/models/module/item')
require_relative('../app/models/module/comment')

include Models

class CommentTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @author = User.created("testuser", "1234a", "test@mail.com")
    @item = @author.create_item("chair", 34, 1)
  end

  def test_initialization
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

  def test_save
    comment = Comment.created(@author, @item, 'test comment')
    assert(comment.id.eql?(1), "wrong id")
    comment.save
    assert(Comment.by_id(1).eql?(comment), "comment should have been stored")

    comment2 = Comment.created(@author, @item, 'comment2')
    assert(comment2.id.eql?(2))

    assert_nil(Comment.by_id(2), "comment2 should not have been stored")
    comment2.save
    assert(Comment.by_id(2).eql?(comment2), "comment2 should have been stored")

  end
end