class Comment
 # A Comment has an id (identifier), an author and there's an item on which the comment corresponds.
 # A Comment may be the answer on a previous comment, but does not have to.

  attr_accessor :id, :author, :correspondent_item , :previous_comment
  @@count = 0

  def self.created(author, correspondent_item, previous_comment = nil)
    comment = self.new
    comment.id = @@count+=1
    comment.author = author
    comment.correspondent_item = correspondent_item
    comment.previous_comment = previous_comment
  end


end