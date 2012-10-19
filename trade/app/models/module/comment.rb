module Models

  class Comment
    # A Comment has an id (identifier), an author and there's an item on which the comment corresponds.
    # A Comment may be the answer on a previous comment, but does not have to.
    # Of course, a comment also has a text.
    # There will be 2 levels of Comments:
    #   - head comments which correspond to an item and do not have a previous comment
    #   - sub comments  which correspond to an item and a head comment

    attr_accessor :id, :author, :correspondent_item, :previous_comment, :text

    @@comment_count = 0
    @@comments = {}

    def self.created(author, correspondent_item, text, previous_comment = nil)
      comment = self.new
      comment.id = @@comment_count + 1
      comment.author = author
      comment.correspondent_item = correspondent_item
      comment.previous_comment = previous_comment
      comment.text = text
      comment
    end
  end

  def self.list_comments(item)
    @@comments.select{|comment| comment.correspondent_item.eql?(item)}
  end

  def save
  # TODO
  end

  def is_head_comment?
    previous_comment.eql?(nil)
  end
end