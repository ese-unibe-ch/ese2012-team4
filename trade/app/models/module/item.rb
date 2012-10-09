module Models

  class Item
    #Items have a name.
    #Items have a price.
    #An item can be active or inactive.
    #An item has an owner.

    # generate getter and setter for name and price
    attr_accessor :name, :price, :active, :owner, :id, :description

    # MW: ToDo: integrate description in tests

    # MW: Since these variables are declared through the attr_accessor, defining getters and setters are unnecessary!

    @@item_list = {}
    @@count = 0

    # factory method (constructor) on the class
    def self.created( name, price, owner, description = "" )
      item = self.new
      item.id = @@count + 1
      item.name = name
      item.price = price
      item.active = false
      item.owner = owner
      item.description = description
      item
    end

    def save
      raise "Duplicated item" if @@item_list.has_key? self.id and @@item_list[self.id] != self
      # MW: How does it make sense to identify an item through the id ( = identifier) AND the name? Name is changeable!
      @@item_list["#{self.id}"] = self
      @@count += 1
    end

    # get state
    def is_active?
      self.active
    end

    # check if a price is valid
    def self.valid_price?(price)
      (!!(price =~ /^[-+]?[1-9]([0-9]*)?$/) && Integer(price) >= 0)
    end

    #compare a users name to the owners name
    def is_owner?(user)
      User.get_user(user).eql?(self.owner)
    end

    # to String-method
    def to_s
      "#{self.name}, #{self.price}"
    end

    #  MW: To do: write a test
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
      @@item_list.delete(self)
    end

  end

end