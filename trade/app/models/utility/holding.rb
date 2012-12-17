module Models

# Manages items that are sold, but not yet received by the buyer.
class Holding
  require 'require_relative'
  require_relative '../module/item'
  require_relative '../utility/mailer'

  @@holder = []

  attr_accessor :item, :seller, :buyer, :quantity, :name, :locked

  def self.get_all
    @@holder
  end

  def self.created (item, seller, buyer, quantity)
    holding = self.new

    holding.item = item
    holding.seller = seller
    holding.buyer = buyer
    holding.quantity = quantity
    holding.locked = true
    #holding.name = "HOOOOOOOLDING"

    @@holder.push(holding)
    holding
  end

  # Moves money after receiving & moves the item to buyers stack
  def item_received
    if(item.currency == "credits")
      seller.credits+=Integer(item.price)*quantity
    end

    if(item.quantity.to_i == quantity)
      # buy all items from seller
      item.owner = buyer
      if(!item.permanent)
        item.owner.remove_offer(item)
      else
        item.switch_permanent
      end
      if !(identical = buyer.list_items_inactive.detect{|i| i == item}).nil?
        identical.quantity+=quantity
      else
        item.quantity = quantity
        buyer.offers.push(item)
        item.active = false
      end
    else
      # seller has some items left
      if !(identical = buyer.list_items_inactive.detect{|i| i == item}).nil?
        identical.quantity+=quantity
      else
        buyer.create_item(item.name,item.price, quantity, item.description).active = false
        #item.active = false
        #buyer.offers.push(item)
      end
    end

    # LD unnoetig seit dem refactoring, glaube ich.
    # item.quantity-=quantity #deletes original item

    @@holder.delete(self) #closes the holding-state

  end

  # Moves the item from seller to holding
  def self.ship_item(item, seller, buyer, quantity)
    item_list = Models::Offer.get_item_list
    item_list.delete(item)

    #seller: remove number of items (or item)
    if (item.permanent)
      copy = item.copy
      copy.quantity = quantity
      item.quantity -= quantity
      copy.save
      holding = self.created(copy, seller, buyer, quantity)
    else

      if (item.quantity == quantity)
        seller.offers.delete(item)
        item.deactivate
      else
        item.quantity -= quantity
      end

      holding = self.created(item,seller,buyer,quantity)
    end

    if item.currency == "credits"
      buyer.credits -= Integer(item.price)*quantity
      holding.locked = false
    end
    if item.currency == "bitcoins"
      Mailer.item_bought(buyer.e_mail, item, seller)
    end

  end

  def self.find_by_id(id)
    @@holder.select{|s| s.item.id.eql?(id.to_i) }
  end

end
end