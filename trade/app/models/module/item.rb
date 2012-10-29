module Models

  # Represents an item in the shop, stores its data and different states.
  # The class stores all created items in a list.
  class Item
    require 'dimensions'
    require 'require_relative'
    require_relative('comment')

    # generate getter and setter for name and price
    attr_accessor :name, :price, :active, :owner, :id, :description, :timestamp, :quantity, :errors, :image, :head_comments, :expiration_date, :wishlist_users

    @@item_list = {}
    @@count = 0
    @comment_count = 0

    def self.get_item_list
      @@item_list
    end

    # factory method (constructor) on the class
    def self.created( name, price, owner, quantity, description = "", image = "")
      item = self.new
      item.id = @@count + 1
      item.name = name
      item.price = price
      item.active = false
      item.owner = owner
      item.quantity = quantity
      item.description = description
      item.image = image
      item.wishlist_users = Array.new
      item.timestamp = Time.now.to_i
      item.head_comments = []
      item
    end

    # Creates a copy of an instance, while replacing the
    # instance variables defined in the parameter hash
    # usage: my_item.copy(:name => "Item2")
    def copy( hash = {})
      item = Models::Item.created(hash[:name] || self.name, hash[:price] || self.price,
                                  hash[:owner] || self.owner, hash[:quantity] ||self.quantity,
                                  hash[:description] || self.description)
    end

    # Controls the item's data. Returns true if there is no invalid data or returns false and adds errors if there is.
    def is_valid
      self.errors = ""
      self.errors += "Price is not a valid number\n" unless Item.valid_integer?(self.price)
      self.errors += "Quantity is not a valid number\n" unless Item.valid_integer?(self.quantity)
      self.errors += "Item must have a name" unless self.name.strip.delete(' ')!=""
      if image != ""
        self.errors += "Image is heavier than 400kB" unless image.size <= 400*1024
        dim = Dimensions.dimensions(image)
        self.errors += "Image is no square" unless dim[0] == dim[1]
        unless image.size <= 400*1024 && dim[0] == dim[1]
          FileUtils.rm(image, :force => true)
        end
      end
      self.errors != "" ? false : true
    end

    # Saves the item to the Item-List
    def save
      raise "Duplicated item" if @@item_list.has_key? self.id and @@item_list[self.id] != self
      @@item_list["#{self.id}"] = self
      @@count += 1
    end

    def edit(name, price, quantity,  description = "", image = "")
      return false if self.active
      self.name = name
      self.price = price
      self.description = description
      if image != ""
        FileUtils.rm(self.image, :force => true)
        self.image = image
      end
      self.quantity = quantity
      self.timestamp = Time.now.to_i
    end

    # Get the activation state.
    # Use this method instead of .active if you want to update the state if the item is expired.
    def is_active?
      if(self.expired?)
        self.active= false
      end
      self.active
    end

    # Checks if the chosen expiration date is exceeded
    def expired?
      if(!self.expiration_date.nil?)
        return Time.now.getlocal > self.expiration_date
      else
        return false
      end
    end

    # Checks if a price is valid
    def self.valid_integer?(price)
      (!!(price =~ /^[-+]?[1-9]([0-9]*)?$/) && Integer(price) >= 0 || (price.is_a? Integer))
    end

    # Compares a users name to the owners name
    def is_owner?(user)
      User.get_user(user).eql?(self.owner)
    end

    # Overrides to String method
    def to_s
      "#{self.name}, #{self.price}"
    end

    def editable?
      !self.active
    end

    # Returns an item by its id.
    def self.get_item(itemid)
      return @@item_list[itemid]
    end

    # Returns all stored Items except those who belong to the given viewer.
    # @param viewer: Name of the user whose items should not be listed.
    def self.get_all(viewer)
      new_array = @@item_list.to_a
      ret_array = Array.new
      for e in new_array
        ret_array.push(e[1])
      end
      ret = ret_array.select {|s| s.owner.name !=  viewer}
      return ret.select {|s| s.is_active?}
    end

    def delete
      self.owner.remove_item(self)
      @@item_list.delete(self)
    end

    # Adds a new Comment on this Item
    # @param author: The User who wrote the Comment
    # @param text: The text of the Comment
    def comment (author, text)
      c = Models::Comment.created(author, self, text)
      c.save
      head_comments[Integer(@comment_count)] = c
      @comment_count = Integer(@comment_count) + 1
      c
    end

    # Returns an Array of items whose names or descriptions contain a keyword and are visible to a certain user.
    # @param s_string: Keywords for whom should be searched. Keywords must be separated by spaces.
    # @param user: The user requesting the item list
    def self.search (s_string, user)
      s_array = s_string.downcase.split
      ret_array = []
      i_array = @@item_list.to_a

      provisional = i_array.select do |item|
        s_array.all?{|keyword| (item[1].name.downcase+" "+item[1].description.downcase).include? keyword.downcase}
      end
      for item in provisional
        i = item[1]
        if i.is_active? or i.owner==user
          ret_array.push(i)
        end
      end
      ret_array
    end

    def add_user_to_wishlist(user)
      wishlist_users.push(user)
    end

    def remove_user_from_wishlist(user)
      wishlist_users.delete(user)
    end
  end
end