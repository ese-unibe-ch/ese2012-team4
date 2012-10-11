require 'rubygems'
require 'bcrypt'
require 'require_relative'
require_relative('item')

module Models

  class User
    #Users have a name.
    #Users have an amount of credits.
    #A new user has originally 100 credit.
    #A user can add a new item to the system with a name and a price; the item is originally inactive.
    #A user provides a method that lists his/her active items to sell.
    #User possesses certain items
    #A user can buy active items of another user (inactive items can't be bought). When a user buys an item, it becomes
    #  the owner; credit are transferred accordingly; immediately after the trade, the item is inactive. The transaction
    #  fails if the buyer has not enough credits.

    # generate getter and setter for name and price
    attr_accessor :name, :credits, :item_list, :pw, :password_hash, :password_salt, :description

    @@users = {}

    # factory method (constructor) on the class
    def self.created( name, password, description = "")
      user = self.new
      user.name = name
      user.description = description
      user.credits = 100
      user.item_list = Array.new
      pw_salt = BCrypt::Engine.generate_salt
      pw_hash = BCrypt::Engine.hash_secret(password, pw_salt)
      user.password_salt = pw_salt
      user.password_hash = pw_hash
      user
    end


    def change_password(password)
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, self.password_salt)
    end

    def check_password(password)
      self.password_hash == BCrypt::Engine.hash_secret(password, self.password_salt)
    end

    def save
      raise "Duplicated user" if @@users.has_key? self.name and @@users[self.name] != self
      @@users[self.name] = self
    end

    #get string representation
    def to_s
      "#{self.name} has currently #{self.credits} credits, #{list_items.size} active and #{list_items_inactive.size} inactive items"
    end

    #let the user create a new item
    def create_item(name, price, description="No description available")
      new_item = Models::Item.created( name, price, self, description )
      self.item_list.push(new_item)
      new_item.save
      return new_item
    end

    #return users item list active
    def list_items
      return_list = Array.new
      for s in self.item_list
        if s.is_active?
          return_list.push(s)
        end
      end
      return return_list
    end

    #return users item list inactive
    def list_items_inactive
      return_list = Array.new
      for s in self.item_list
        if !s.is_active?
          return_list.push(s)
        end
      end
      return return_list
    end

    # buy an item
    # @return true if user can buy item, false if his credit amount is too small
    def buy_new_item?(item_to_buy)
      if item_to_buy.price > self.credits
        return false
      end
      self.credits = self.credits - item_to_buy.price
      item_to_buy.active = false
      item_to_buy.owner = self        #BS: replaced setter
      self.item_list.push(item_to_buy)
      return true
    end

    # removing item from users item_list
    def remove_item(item_to_remove)
      self.credits = self.credits + item_to_remove.price
      self.item_list.delete(item_to_remove)
    end

    def self.login name, password
      user = @@users[name]
      return false if user.nil?
      user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
    end

    def self.get_user(username)
      return @@users[username]
    end


    def self.get_all(viewer)
      new_array = @@users.to_a
      ret_array = Array.new
      for e in new_array
        ret_array.push(e[1])
      end
      return ret_array.select {|s| s.name !=  viewer}
    end

    def self.available? name
      not @@users.has_key? name
    end

    def delete
      @@users.delete(self.name)
    end

  end

end