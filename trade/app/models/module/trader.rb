require 'require_relative'
require_relative('../utility/mailer')
require_relative('item')
require_relative('auction')
require_relative('../utility/holding')


module Models

  # Abstract class for trading items in the System.
  # Do not try to create a trader directly, known subclasses are: User, Organisation
  # Traders have a name.
  # Traders have an amount of credits.
  # A new trader has originally 100 credit.
  # A trader can add a new item to the system with a name and a price; the item is originally inactive.
  # A trader provides a method that lists his/her active items to sell.
  # Trader possesses certain items
  # A trader can buy active items of another trader.
  class Trader
    # [String]
    attr_accessor :name
    # [Integer]: The owned money in credits
    attr_accessor :credits
    # [Array]: All the items the trader possesses
    attr_accessor :item_list
    # [Array]: All the auctions the user possesses
    attr_accessor :auctions_list
    # [String]: List interests or other things about this owner
    attr_accessor :description
    # [Integer]
    attr_accessor :id
    # [String]: Stores all error messages
    attr_accessor :errors
    # [String]: The path of an image
    attr_accessor :image
    # [Array]: All the items, this user is interested in
    attr_accessor :wishlist
    # [Array]: Ratings of other users
    attr_accessor :ratings
    # [Boolean]: check if trader is an organization, used primarily for views
    attr_accessor :organization


    @@traders_by_name = {}
    @@traders = {}
    @@count = 0

    def initialize(name, description, image)
      self.name = name
      self.id = @@count +1
      self.description = description
      self.image = image
      self.wishlist = Array.new
      self.credits = 100
      self.item_list = Array.new
      self.auctions_list = Array.new
      self.ratings = []
      self.organization = false
    end

    # - @return [User]: the user with the given username
    # ToDo: maybe we need to adapt this, if we want to list organizations and users differently...
    def self.by_name(name)
      return @@traders_by_name[name.downcase]
    end


    def save
      raise "Duplicated user" if @@traders.has_key? self.id and @@traders[self.id] != self
      @@traders[self.id] = self
      @@traders_by_name[self.name.downcase] = self
      @@count += 1
    end

    # Lets the trader create a new item
    # - @param name
    # - @param price
    # - @param quantity
    # - @param description
    # - @param image
    # - @return [Item]: the created item
    def create_item(name, price, quantity, description="No description available", image="")
      new_item = Item.created( name, price, self, quantity, description, image)
      if !(identical = self.list_items_inactive.detect{|i| i.name== new_item.name and i.price == new_item.price and i.description==new_item.description}).nil?
        identical.quantity += new_item.quantity
      else
        self.item_list.push(new_item)
        new_item.save
      end
      return new_item
    end

    # Return a list of the trader's active items
    # - @return [Array]: The traders active items
    def list_items
      return_list = Array.new
      for s in self.item_list
        if s.is_active?
          return_list.push(s)
        end
      end
      return return_list
    end

    # Return a list of the trader's inactive items
    # - @return [Array] The trader's inactive items
    def list_items_inactive
      return_list = Array.new
      for s in self.item_list
        if !s.active && !s.expired? && !Auction.auction_by_item(s)
          return_list.push(s)
        end
      end
      return return_list
    end

    # When a trader buys an item, it becomes the owner;
    # credit are transferred accordingly; immediately after the trade, the item is inactive.
    # The transaction fails if the buyer has not enough credits.
    # - @param item_to_buy
    # - @param quantity: how many pieces of this item should be bought
    # - @return true if user can buy item, false if his credit amount is too small
    def buy_new_item(item_to_buy, quantity)
      preowner = item_to_buy.owner

      if Integer(item_to_buy.price*quantity) > self.credits or Integer(item_to_buy.quantity)<quantity
        return false
      end

      if !item_to_buy.wishlist_users.empty? and item_to_buy.quantity == quantity
        item_to_buy.wishlist_users.each {|trader| trader.remove_from_wishlist(item_to_buy); item_to_buy.wishlist_users.delete(trader)}
      end

      Holding.shipItem(item_to_buy, item_to_buy.owner, self, quantity)

      Mailer.item_sold(preowner.e_mail, "Hi #{preowner.name}, \n #{self.name} bought your Item #{item_to_buy.name}.
        Please Contact him for completing the trade. His E-Mail is: #{self.e_mail}")
      return true
    end

    # Removing item from trader's item list
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

    # Deactivates an item, removes it from everybody's wishlist and sets expiration_date to nil
    # - @param [Integer] id: The Item's id
    def deactivate_item(id)
      item = Item.get_item(id)
      return false unless item.owner==self
      if !(identical = self.list_items_inactive.detect{|i| i.name== item.name and i.price == item.price and i.description==item.description}).nil?
        identical.quantity+=item.quantity
        item.delete
      end
      item.active = false
      item.expiration_date=nil

      if !item.wishlist_users.empty?
        item.wishlist_users.each {|user| user.remove_from_wishlist(item); item.wishlist_users.delete(user)}
      end
    end

    # - @return [Array]: all users except the given viewer
    def self.get_all(viewer)
      new_array = @@traders.to_a
      ret_array = Array.new
      for e in new_array
        ret_array.push(e[1])
      end
      return ret_array.select {|s| !s.eql?(viewer)}
    end

    # - @return true, if the given name is the name of an existing user
    def self.available?(name)
      not @@traders_by_name.has_key? name.downcase
    end

    def self.clear_all
      @@traders.each{|user|
        FileUtils::rm(user.image, :force => true)
        @@traders.delete(user.id)
        @@traders_by_name.delete(user.name.downcase)}
    end

    # - @return [Array]: all the pending items to buy of this user
    def pending_inbox
      Models::Holding.get_all.select {|s| s.buyer == self}
    end

    # - @return [Array]: all the pending items to sell of this user
    def pending_outbox
      Models::Holding.get_all.select {|s| s.seller == self}
    end

    def delete
      FileUtils::rm(self.image, :force => true)
      @@traders.delete(self.id)
      @@traders_by_name.delete(self.name.downcase)
      Item.get_item_list.delete_if {|k,v| v.owner == self }
      Auction.auctions_by_user(self).each{|auction|
        Auction.all_auctions.delete(auction)
        self.auctions_list.delete(auction)
      }
    end

    def add_to_wishlist(item)
      self.wishlist.push(item)
      item.add_user_to_wishlist(self)
    end

    def remove_from_wishlist(item)
      item.remove_user_from_wishlist(self)
      self.wishlist.delete(item)
    end

    def add_rating(rating)
      self.ratings.push rating
    end

    # Returns a json representation of the user's ratings
    # We removed the need for the json gem (because it requires the
    # additional DevKit installation on Windows, which is not
    # allowed in the deliverable). This generates a json-representation
    # the dirty way
    def ratings_json
      colors = ['#ff6f31',   # color for bad
                '#ff9f02',
                '#ffcf02',
                '#a4cc02',
                '#88b131']    # color for good

      values = Array.new(5, 0)  # size, initial value
      self.ratings.each do |v|
        values[v.to_i]+=1       # count number of votes for every rating value
      end
      data = "["                # generate json
      values.each_with_index do |value, index|
        entry = "{'data':[["+values[index].to_s+","+(index+1).to_s+"]],'color':'"+colors[index]+"'},"
        data = data + entry
      end
      data = data + "]"
      data
    end

    # - @return [Integer]: the average rating of the user
    def rating
      counter = 0
      value = 0
      self.ratings.each do |v|
        value = value + v
        counter = counter + 1
      end
      return value/counter unless counter == 0
      return 0
    end

    # AS intermezzo sets an item as auction
    def set_to_auction(item)
      self.item_list.delete(item) #AS Not sure if it works that simple, because they have concepts like quantity. But let's face the problems as they appear.
      self.auctions_list.push(item)
    end

    def <=>(o)
      # Compare user name
      user_name_cmp = self.name <=> o.name
      return user_name_cmp unless user_name_cmp == 0

      # Otherwise, compare IDs
      return self.id <=> o.id
    end
  end
end