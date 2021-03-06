require 'require_relative'
require_relative('../utility/mailer')
require_relative('item')
require_relative('auction')
require_relative('activity')
require_relative('../utility/holding')


module Models

  # Abstract class for trading offers in the System.
  # Do not try to create a trader directly, known subclasses are: User, Organisation
  # Traders have a name.
  # Traders have an amount of credits.
  # A new trader has originally 100 credit.
  # A trader can add a new item to the system with a name and a price; the item is originally inactive.
  # A trader provides a method that lists his/her active items to sell.
  # Trader possesses certain offers
  # A trader can buy active offers of another trader.
  class Trader
    # [String]
    attr_accessor :name
    # [Integer]: The owned money in credits
    attr_accessor :credits
    # [Array]: All the offers the trader possesses
    attr_accessor :offers
    # [String]: List interests or other things about this owner
    attr_accessor :description
    # [Integer]
    attr_accessor :id
    # [String]: Stores all error messages
    attr_accessor :errors
    # [String]: The path of an image
    attr_accessor :image
    # [Array]: All the offers, this user is interested in
    attr_accessor :wishlist
    # [Array]: Ratings of other users
    attr_accessor :ratings
    # [Boolean]: check if trader is an organization, used primarily for views
    attr_accessor :organization
    # [Array]: all activites of this user or users of this organization
    attr_accessor :activities
    # [Array]: list of traders that are being followed
    attr_accessor :watching

    attr_accessor :e_mail
    attr_accessor :wallet

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
      self.offers = Array.new
      self.ratings = []
      self.organization = false
      self.activities = []
      self.watching = []
    end

    # - @return [User]: the user with the given username
    def self.by_name(name)
      return @@traders_by_name[name.downcase]
    end

    # Saves the trader to the trader list. Access the list with the get_all method.
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
      new_item = Item.created( name, price, self.working_for, quantity, description, image)
      if !(identical = self.working_for.list_items_inactive.detect{|i| i == new_item }).nil?
        identical.quantity += new_item.quantity
      else
        self.working_for.offers.push(new_item)
        new_item.save
      end
      Activity.log(self, "add_item", new_item, self.working_for)
      return new_item
    end

    # Return a list of the trader's active items
    # - @return [Array]: The traders active items
    def list_items
      return_list = Array.new
      for s in self.offers
        unless s.auction
          if s.is_active?
            return_list.push(s)
          end
        end
      end
      return return_list
    end

    # - @return [Array]: All the trader's auctions
    def list_auctions
      self.offers.select{|s| s.auction}
    end

    # Return a list of the trader's inactive items
    # - @return [Array] The trader's inactive items
    def list_items_inactive
      return_list = Array.new
      for s in self.offers
        unless s.auction
          if !s.active && !s.auction
            return_list.push(s)
          end
        end
      end
      return return_list
    end

    # When a trader buys an item, it becomes the owner;
    # credit are transferred accordingly; immediately after the trade, the item is inactive.
    # The transaction fails if the buyer has not enough credits.
    # - @param item_to_buy
    # - @param quantity: how many pieces of this item should be bought
    # - @return true if user can buy the offer, false if his credit amount is too small
    def buy_new_item(item_to_buy, quantity, account)
      return false if item_to_buy.auction
      preowner = item_to_buy.owner

      if (Integer(item_to_buy.price*quantity) > self.credits and item_to_buy.currency == "credits") or Integer(item_to_buy.quantity)<quantity
        Activity.log(account, "item_bought_failure", item_to_buy, self)
        Activity.log(account, "item_sold_failure", item_to_buy, preowner)
        return false
      end


      if !item_to_buy.wishlist_users.empty? and item_to_buy.quantity == quantity and !item_to_buy.permanent
        item_to_buy.wishlist_users.each {|trader| trader.remove_from_wishlist(item_to_buy); item_to_buy.wishlist_users.delete(trader)}
      end

      Holding.ship_item(item_to_buy, item_to_buy.owner, self, quantity)
      Activity.log(account, "item_bought_success", item_to_buy, self)
      Activity.log(account, "item_sold_success", item_to_buy, preowner)
      Mailer.item_sold(preowner.e_mail, "Hi #{preowner.name}, \n #{self.name} bought your Item #{item_to_buy.name}.
        Please Contact him for completing the trade. His E-Mail is: #{self.e_mail}")

      return true
    end


    # - @param [Integer] id: The offers ID
    def activate_item(id)
      item = Offer.get_offer(id)
      return false unless item.owner == self.working_for
      if !(identical = self.working_for.list_items.detect{|i| i == item }).nil?
        identical.quantity+=item.quantity
        item.delete
      else
      item.active=true
      end
      Activity.log(self, "activate_item", item, self.working_for)
    end

    # Invokes the edit method of an item and logs this activity to the traders log.
    def edit_item(item, name, price, quantity, currency, description = "", image = "")
      item.edit(name, price, quantity, currency, description, image)
      Activity.log(self, "edit_item", item, self.working_for)
    end

    # Invokes the comment method of an item and logs this activity to the traders log.
    def comment_item(item, text)
      item.comment(self, text)
      Activity.log(self, "comment_item", item, item.owner)
    end

    # Invokes the answer method of a comment and logs this activity to the traders log.
    def answer_comment(comment, text)
      comment.answer(self, text)
      item = comment.correspondent_item
      Activity.log(self, "comment_item", item, item.owner)
    end

    # Deactivates an item, removes it from everybody's wishlist and sets expiration_date to nil
    # - @param [Integer] id: The Item's id
    def deactivate_item(id)
      item = Offer.get_offer(id)
      return false unless item.owner == self.working_for
      if !(identical = self.list_items_inactive.detect{|i| i == item }).nil?
        identical.quantity+=item.quantity
        item.delete
      else
      item.active = false
      item.expiration_date=nil
      end

      if !item.wishlist_users.empty?
        item.wishlist_users.each {|user| user.remove_from_wishlist(item); item.wishlist_users.delete(user)}
      end
      Activity.log(self, "deactivate_item", item, self.working_for)
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

    # Deletes the trader from the system and removes all his offers.
    def delete
      FileUtils::rm(self.image, :force => true)
      @@traders.delete(self.id)
      @@traders_by_name.delete(self.name.downcase)
      unless !self.offers.empty?
        for offer in self.offers
          offer.delete
        end
      end
      self.list_auctions.each{|auction|
        Auction.all_offers.delete(auction)
        self.auctions_list.delete(auction)
      }
    end

    def add_to_wishlist(offer)
      unless wishlist.include?(offer)
        self.wishlist.push(offer)
        offer.add_user_to_wishlist(self)
      end
    end

    def remove_from_wishlist(offer)
      offer.remove_user_from_wishlist(self)
      self.wishlist.delete(offer)
    end

    def add_rating(rating)
      self.ratings.push rating
    end

    # - @return [Integer]: the average rating of the user
    def rating
      if self.ratings.size != 0
        counter = 0
        value = 0
        self.ratings.each do |v|
          value = value + v.to_i
          counter = counter + 1
        end
        return value/counter
      else
        return 0
      end
    end

    # Removes an item from the owner's list
    def remove_offer(offer)
      self.offers.delete(offer) #AS Not sure if it works that simple, because they have concepts like quantity. But let's face the problems as they appear.
    end

    def add_offer(offer)
      self.offers.push(offer)
    end

    def <=>(o)
      # Compare user name
      user_name_cmp = self.name <=> o.name
      return user_name_cmp unless user_name_cmp == 0

      # Otherwise, compare IDs
      return self.id <=> o.id
    end

    def watch(trader)
      watching.push(trader) unless (trader.eql?(self) or watching.include?(trader))
    end

    def unwatch(trader)
      watching.delete(trader)
    end

    def get_watching_logs(filter = ["add_item", "edit_item", "activate_item", "deactivate_item"])
      watching_logs = Array.new
      watching.each do |trader|
        trader.get_activities(filter).each do |act|
          watching_logs.push(act)
        end
        #trader.activities.each do |a|
        #  if(a.topic=="add_item" || a.topic=="edit_item" || a.topic=="activate_item" || a.topic=="deactivate_item")
        #    watching_logs.push(a)
        #  end
        #end
      end
      watching_logs.sort{|a,b| b.time <=> a.time}
    end


    # Returns activities of the types given in the filter array.
    # If the Array is empty, the method returns all activities of this user.
    def get_activities(filter = Array.new)
      ret_array = Array.new
      if filter.size > 0
        for act in self.activities
          filter.each do |f|
            if act.topic == f
              ret_array.push(act)
            end
          end
        end
      else
        ret_array = activities
      end
      ret_array.sort{|a,b| b.time <=> a.time}

    end
  end
end
