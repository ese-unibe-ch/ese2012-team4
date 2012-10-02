module Models

  class Item
    #Items have a name.
    #Items have a price.
    #An item can be active or inactive.
    #An item has an owner.

    # generate getter and setter for name and price
    attr_accessor :name, :price, :active, :owner, :id

    @@item_list = {}
    @@count = 0

    # factory method (constructor) on the class
    def self.created( name, price, owner )
      item = self.new
      item.id = @@count + 1
      item.name = name
      item.price = price
      item.active = false
      item.owner = owner
      item
    end

    def save
      raise "Duplicated item" if @@item_list.has_key? self.id and @@item_list[self.id] != self
      @@item_list["#{self.id}.#{self.name}"] = self
      @@count += 1
    end

    # get state
    def is_active?
      self.active
    end

    # set owner
    def set_owner(new_owner)
      self.owner = new_owner
    end

    # to String-method
    def to_s
      "#{self.get_name}, #{self.get_price}"
    end

    # to set active
    def to_active
      self.active = true
    end

    # to set inactive
    def to_inactive
      self.active = false
    end

    # get name
    def get_name
      # string interpolation
      "#{name}"
    end

    # get price
    def get_price
      # int interpolation
      self.price
    end

    # return the owner
    def get_owner
      self.owner
    end

    def self.get_item(itemid)
      return @@item_list[itemid]
    end

  end

end