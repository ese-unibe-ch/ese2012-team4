module Models
  class Item
    require 'dimensions'

    #Items have a name.
    #Items have a price.
    #An item can be active or inactive.
    #An item has an owner.

    # generate getter and setter for name and price
    attr_accessor :name, :price, :active, :owner, :id, :description, :timestamp, :quantity, :errors, :image, :head_comments

    @@item_list = {}
    @@count = 0

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
      item.timestamp = Time.now.to_i
      item
    end

    # LD maybe we can use this some time. Creates a copy of an instance, while replacing the
    # instance variables defined in the parameter hash
    # usage: my_item.copy(:name => "Item2")
    def copy( hash = {})
      item = Models::Item.created(hash[:name] || self.name, hash[:price] || self.price,
                                  hash[:owner] || self.owner, hash[:quantity] ||self.quantity,
                                  hash[:description] || self.description)
    end
    
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

    # get state
    def is_active?
      self.active
    end

    # check if a price is valid
    def self.valid_integer?(price)
      (!!(price =~ /^[-+]?[1-9]([0-9]*)?$/) && Integer(price) >= 0 || (price.is_a? Integer))
    end

    #compare a users name to the owners name
    def is_owner?(user)
      User.get_user(user).eql?(self.owner)
    end

    # to String-method
    def to_s
      "#{self.name}, #{self.price}"
    end

    def editable?
      !self.active
    end

    def self.get_item(itemid)
      return @@item_list[itemid]
    end

    #def self.get_all(viewer)
    #  return @@item_list.select {|s| s.owner.name !=  viewer}
    #end
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

    def comment (author, text, prev_comment = nil)
      Comment.created(author, self, text, prev_comment)
    end

  end

end