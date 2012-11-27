module Models

# Manages items that are sold, but not yet received by the buyer.
class Holding
  require 'require_relative'
  require_relative '../module/item'

  @@holder = []

  attr_accessor :item, :seller, :buyer, :quantity, :name

  def self.get_all
    @@holder
  end

  def self.created (item, seller, buyer, quantity)
    holding = self.new

    holding.item = item
    holding.seller = seller
    holding.buyer = buyer
    holding.quantity = quantity
    #holding.name = "HOOOOOOOLDING"

    @@holder.push(holding)
  end

  # Moves money after receiving & moves the item to buyers stack
  def itemReceived
    seller.credits+=Integer(item.price)*quantity

    if(item.quantity.to_i == quantity)
      # buy all items from seller
      item.owner = buyer
      item.owner.remove_offer(item)
      if !(identical = buyer.list_items_inactive.detect{|i| i.name== item.name and i.price == item.price and i.description==item.description}).nil?
        identical.quantity+=quantity
      else
        item.quantity = quantity
        buyer.offers.push(item)
        item.active = false
      end
    else
      # seller has some items left
      if !(identical = buyer.list_items_inactive.detect{|i| i.name== item.name and i.price == item.price and i.description==item.description}).nil?
        identical.quantity+=quantity
      else
        #buyer.create_item(item.name,item.price, quantity, item.description).active = false
        item.active = false
        buyer.offers.push(item)
      end
    end

    # LD unnoetig seit dem refactoring, glaube ich.
    # item.quantity-=quantity #deletes original item

    @@holder.delete(self) #closes the holding-state

  end

  # Moves the item from seller to holding
  def self.shipItem(item, seller, buyer, quantity)
    item_list = Models::Offer.get_item_list
    item_list.delete(item)

    buyer.credits -= Integer(item.price)*quantity


    #seller: remove number of items (or item)
    if (item.quantity == quantity)
      seller.offers.delete(item)
    else
      item.quantity -= quantity
    end

    holding = self.created(item,seller,buyer,quantity)
  end

end
end