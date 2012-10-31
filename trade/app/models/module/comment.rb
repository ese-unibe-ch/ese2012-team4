module Models

  # A Comment has an id (identifier), an author and there's an item on which the comment corresponds.
  # A Comment may be the answer on a previous comment, but does not have to.
  # Of course, a comment also has a text.
  # There will be 2 levels of Comments:
  #   - head comments which correspond to an item and do not have a previous comment
  #   - sub comments  which correspond to an item and a head comment
  class Comment
    @@comment_count = 0
    @@comments = []

    # [Integer]: The identifier of this Comment
    attr_accessor :id
    # [User]: The user that wrote this Comment
    attr_accessor :author
    # [Item]: Item on which the Comment is made
    attr_accessor :correspondent_item
    # [Comment]
    attr_accessor :previous_comment
    # [String]
    attr_accessor :text
    # [Array]: All the Comments on this Comment
    attr_accessor :sub_comments


    # - @param [User] author
    # - @param [Item] correspondent_item
    # - @param [String] text
    # - @param [Comment] previous_comment
    def self.created(author, correspondent_item, text, previous_comment = nil)
      comment = self.new
      comment.id = @@comment_count + 1
      comment.author = author
      comment.correspondent_item = correspondent_item
      comment.previous_comment = previous_comment
      comment.text = text
      comment.sub_comments = []
      comment
    end

    def self.list_comments(item)
      @@comments.select{|comment| comment.correspondent_item.eql?(item)}
    end

    def save
      @@comments[self.id] = self
      @@comment_count +=1
    end

    # Removes a comment (and with it all its subcomments) from the @@comments list, if it's a head comment.
    # If it's a subcomment, it will delete it from the head Comment's list 'sub_comments'
    def delete
      if is_head_comment?
        @@comments.delete self
      else
        head_comment = self.previous_comment
        head_comment.sub_comments.delete(self)
      end
    end

    def is_head_comment?
      previous_comment.eql?(nil)
    end

    def self.by_id id
      @@comments[id.to_i]
    end

    # Adds a new Comment to this Comment
    # - @param [User] author
    # - @param [String] text
    # - @return [Comment]: Returns the new sub-comment or false, if it is no head-comment
    def answer (author, text)
      if is_head_comment?
        answer = Comment.created(author, self.correspondent_item, text, self)
        sub_comments.push(answer)
        answer
      else
        false
      end

    end
  end
end