module Models
  class Offer
    require 'dimensions'
    require 'require_relative'
    require_relative('comment')
    require_relative('user')
    require_relative('item')
    require_relative('auction')

    # [String]: The offers's name
    attr_accessor :name
    # [Integer]: The price in credits
    attr_accessor :owner
    # [Integer]: Identifier
    attr_accessor :id
    # [String]: Detailed description
    attr_accessor :description
    # [Time]: Time the Offer last changed
    attr_accessor :timestamp
    # [Integer]
    attr_accessor :quantity
    # [String]: Stores all error messages
    attr_accessor :errors
    # [String]: The path of an image
    attr_accessor :image
    # [Comment]: Comments on the Item
    attr_accessor :head_comments
    # [Time]: Stores when the offer deactivates automatically
    attr_accessor :expiration_date
    # [Array]: Stores on whose wishlists the offer is
    attr_accessor :wishlist_users
    # [Bool]: Stores whether the offer is an auction or not
    attr_accessor :auction
    # [Category]: The category the offer belongs to
    attr_accessor :category
    # [String]: Bitcoins or credits
    attr_accessor :currency
    attr_accessor :wallet

    @@count = 0
    @@offers = {}

    # - @param [User] viewer: Name of the user whose items should not be listed.
    # - @param [Hash] options: Options for sorting the list, usage: {:order_by => "name", :order_direction => "asc"}
    # - @return [Array]: Array of all stored Items except those who belong to the given viewer.
    def self.get_all(viewer = nil, options = {})
      o = {
          :order_by => 'name',
          :order_direction => 'asc'
      }.merge(options)

      if viewer.is_a?(User)
        viewer = viewer.name
      end

      new_array = @@offers.to_a
      ret_array = Array.new
      for e in new_array
        unless e[1].nil?
          ret_array.push(e[1])
        end
      end
      ret = ret_array.select{|s| s.owner.name !=  viewer}
      if o[:order_direction] == 'asc'
        return ret.select{|s| s.is_active? }.sort{ |a,b| a.send(o[:order_by]) <=> b.send(o[:order_by]) }
      else
        return ret.select{|s| s.is_active?}.sort{ |a,b| b.send(o[:order_by]) <=> a.send(o[:order_by]) }
      end
    end

    def delete
      self.owner.remove_offer(self)
      @@offers[self.id]=nil

    end

    def self.get_item_list
      @@offers
    end

    def add_user_to_wishlist(user)
      wishlist_users.push(user)
    end

    def remove_user_from_wishlist(user)
      wishlist_users.delete(user)
    end

    # Saves the offer to the Offer-List
    def save
      if @@offers.empty?
        @@offers = Hash.new
      end
      unless self.auction
        raise "Duplicated item" if @@offers.has_key? self.id and @@offers[self.id] != self
      else
        raise "Duplicated item" if @@offers.has_key? self.id and @@offers[self.id] and @@offers[self.id] != self.item
      end
      @@offers[self.id] = self
      @@count += 1
    end

    def expired?
      if(!self.expiration_date.nil?)
        return Time.now.getlocal > self.expiration_date
      else
        return false
      end
    end

    def self.remove_from_list(offer)
      @@offers[offer.id] = nil
    end

    # Compares a users name to the owners name.
    # - @param [String] username: The name of the user to be compared.
    def is_owner?(username)
      User.get_user(username).eql?(self.owner)
    end

    # Returns an offer by its id.
    # - @param [Integer] offerid: The id of the Item to be selected.
    # - @return [Item]: The selected Item.
    def self.get_offer(offerid)
      return @@offers[offerid.to_i]
    end

  end
end