require 'rubygems'
require 'bcrypt'
require 'require_relative'
require 'fileutils'
require 'json'
require_relative('../utility/mailer')
require_relative('../utility/password_check')
require_relative('item')
require_relative('../utility/holding')


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
    attr_accessor :name, :credits, :item_list, :password_hash, :password_salt, :description, :e_mail, :id, :errors, :image, :ratings

    @@users_by_name = {}
    @@users = {}
    @@count = 0

    # factory method (constructor) on the class
    def self.created( name, password, e_mail, description = "", image = "")
      user = self.new
      user.name = name
      user.e_mail = e_mail
      user.id = @@count +1
      user.description = description
      user.image = image
      user.credits = 100
      user.item_list = Array.new
      pw_salt = BCrypt::Engine.generate_salt
      pw_hash = BCrypt::Engine.hash_secret(password, pw_salt)
      user.password_salt = pw_salt
      user.password_hash = pw_hash
      user.ratings = {}
      user
    end

    # LD maybe we can use this some time. Creates a copy of an instance, while replacing the
    # instance variables defined in the parameter hash
    # usage: user1.copy(:name => "User 2")
    def copy( hash = {} )
      Models::User.created(hash[:name] || self.name, "FdZ.(gJa)s'dFjKdaDGS+J1",
                           hash[:e_mail] || self.e_mail,
                           hash[:description] || self.description)
    end

    def is_valid(pw = nil, pw2 = nil, check_username_exists = true)
      self.errors = ""
      self.errors += "User must have a name\n" unless self.name.strip.delete(' ')!=""
      self.errors += "Invalid e-mail\n" if self.e_mail=='' || self.e_mail.count("@")!=1 || self.e_mail.count(".")==0
      self.errors += "Username already chosen\n" unless (User.available? self.name) || !check_username_exists
      if pw != nil || pw2 != nil
        if pw != nil || pw != ""
          if pw2 == nil || pw2 == ""
            self.errors += "Password confirmation is required\n"
          else
            self.errors += "Passwords do not match\n" unless pw == pw2
            password_check = Models::PasswordCheck.created
            self.errors += "Password is not safe\n" unless password_check.safe?(pw)
          end
        else
          self.errors += "Password is required"
        end
      end
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

    def change_password(password)
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, self.password_salt)
    end

    def check_password(password)
      self.password_hash == BCrypt::Engine.hash_secret(password, self.password_salt)
    end

    def save
      raise "Duplicated user" if @@users.has_key? self.id and @@users[self.id] != self
      @@users[self.id] = self
      @@users_by_name[self.name.downcase] = self
      @@count += 1
    end

    #get string representation
    def to_s
      "#{self.name} has currently #{self.credits} credits, #{list_items.size} active and #{list_items_inactive.size} inactive items"
    end

    #let the user create a new item
    def create_item(name, price, quantity, description="No description available", image="")
      new_item = Models::Item.created( name, price, self, quantity, description, image)
      if !(identical = self.list_items_inactive.detect{|i| i.name== new_item.name and i.price == new_item.price and i.description==new_item.description}).nil?
        identical.quantity += new_item.quantity
      else
        self.item_list.push(new_item)
        new_item.save
      end
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
    def buy_new_item(item_to_buy, quantity)
      preowner = item_to_buy.owner

      if Integer(item_to_buy.price*quantity) > self.credits or Integer(item_to_buy.quantity)<quantity
        return false
      end

        Models::Holding.shipItem(item_to_buy, item_to_buy.owner, self, quantity)

      #Models::Mailer.send_mail_to(preowner.e_mail, "Hi #{preowner.name}, \n #{self.name} bought your Item #{item_to_buy.name}.
      #  Please Contact him for completing the trade. His E-Mail is: #{self.e_mail}")
      return true
    end

    # removing item from users item_list
    def remove_item(item_to_remove)
      self.item_list.delete(item_to_remove)
    end

    def activate_item(id)
      item = Item.get_item(id)
      return false unless item.owner==self
      if !(identical = self.list_items.detect{|i| i.name== item.name and i.price == item.price and i.description==item.description}).nil?
        identical.quantity+=item.quantity
        item.delete
      end
      item.active=true
    end

    def deactivate_item(id)
      item = Item.get_item(id)
      return false unless item.owner==self
      if !(identical = self.list_items_inactive.detect{|i| i.name== item.name and i.price == item.price and i.description==item.description}).nil?
        identical.quantity+=item.quantity
        item.delete
      end
      item.active = false
    end

    def self.login id, password                #BS: change parameter "name" to "id"
      user = @@users[id]
      return false if user.nil?
      user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
    end

    def self.get_user(user_id)           #BS: change parameter "name" to "id"
      return @@users[user_id.to_i]
    end

    def self.by_name(name)
      return @@users_by_name[name]
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
      not @@users_by_name.has_key? name.downcase
    end
    
    def pending_inbox
      Models::Holding.get_all.select {|s| s.buyer == self}
    end
    
    def pending_outbox
      Models::Holding.get_all.select {|s| s.seller == self}
    end

    def delete
      FileUtils::rm(self.image, :force => true)
      @@users.delete(self.id)
      @@users_by_name.delete(self.name.downcase)
    end

    def has_rated(seller)
      seller.rating_from self != nil
    end

    def add_rating(seller, rating)
      self.ratings[seller] = rating
    end
    
    def rating_from user
      user = User.get_user(user.id)
      self.ratings[user]
    end
    
    def ratings_json
      colors = ['#FF0000','#FF8000','#9EFF3D','#00FF00']
      
      values = Array.new(4, 0)  # size, initial value
      self.ratings.each_pair do |k,v|
        values[v.to_i]+=1
      end
      data = []
      values.each_with_index do |value, index|
        hash = Hash.new
        hash[:data] = [[values[index], index+1]]
        hash[:color] = colors[index]
        data.push(hash)
      end
      data.to_json
    end
    
    def rating
      counter = 0
      value = 0
      self.ratings.each_pair do |k,v|
        value = value + v
        counter = counter + 1
      end
      value/counter
    end
  end
end