module Trading

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
    attr_accessor :name, :credits, :item_list

    # factory method (constructor) on the class
    def self.created( name )
      item = self.new
      item.name = name
      item.credits = 100
      item.item_list = Array.new
      item
    end

    # get string representation of users name
    def get_name
      "#{self.name}"
    end

    #get amount of users credits
    def get_credits
      self.credits
    end

    #get string representation
    def to_s
      "#{self.name} has currently #{self.credits} credits, #{list_items.size} active and #{list_items_inactive.size} inactive items"
    end

    #let the user create a new item
    def create_item(name, price)
      new_item = Trading::Item.created( name, price, self )
      self.item_list.push(new_item)
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
    # @return true if user can buy item, false if his credit amount is to small
    def buy_new_item?(item_to_buy)
      if item_to_buy.get_price > self.credits
        return false
      end
      self.credits = self.credits - item_to_buy.get_price
      item_to_buy.to_inactive
      item_to_buy.set_owner(self)
      self.item_list.push(item_to_buy)
      return true
    end

    # removing item from users item_list
    def remove_item(item_to_remove)
      self.credits = self.credits + item_to_remove.get_price
      self.item_list.delete(item_to_remove)
    end

  end

end
