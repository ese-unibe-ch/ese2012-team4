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
    assert(comment.author.eql?(@author), "wrong author")
    assert(comment.correspondent_item.eql?(@item), "wrong correspondent item")
    assert_nil(comment.previous_comment)
  end

  def test_is_head_comment
    comment = Comment.created(@author, @item, 'test comment')
    assert(comment.is_head_comment?, "should be a head comment")
  end

  def test_save
    comment = Comment.created(@author, @item, 'test comment')
    comment.save
    assert(Comment.by_id("#{comment.id}").eql?(comment), "comment should have been stored")

    comment2 = Comment.created(@author, @item, 'comment2')
    assert_nil(Comment.by_id("#{comment2}"), "comment2 should not have been stored")

    comment2.save
    assert(Comment.by_id("#{comment2.id}").eql?(comment2), "comment2 should have been stored")
  end

  def test_delete
    comment = Comment.created(@author, @item, 'test comm')
    comment.save

    assert(Comment.by_id("#{comment.id}").eql?(comment))
    comment.delete
    assert_nil(Comment.by_id("#{comment.id}"), "comment should have been deleted")
  end

  def test_answer
    comment = Comment.created(@uathor, @item, 'head comment')
    answer = comment.answer(@author, 'subcomment')

    assert(!answer.is_head_comment?, "this is no head comment!")
    assert(comment.sub_comments.include?(answer))

    answer.delete
    assert(!comment.sub_comments.include?(answer))
  end
end