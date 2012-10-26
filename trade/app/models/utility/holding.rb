module Models
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

  #moves Money after receiving & moves the item to buyers stack
  def itemReceived
    seller.credits+=Integer(item.price)*quantity

    if(item.quantity.to_i == quantity)
      # buy all items from seller
      item.owner = buyer
      item.owner.remove_item(item)
      if !(identical = buyer.list_items_inactive.detect{|i| i.name== item.name and i.price == item.price and i.description==item.description}).nil?
        identical.quantity+=quantity
      else
        item.quantity = quantity;
        buyer.item_list.push(item)
      end
    else
      # seller has some items left
      if !(identical = buyer.list_items_inactive.detect{|i| i.name== item.name and i.price == item.price and i.description==item.description}).nil?
        identical.quantity+=quantity
      else
        buyer.create_item(item.name,item.price, quantity, item.description)
      end
    end

    # LD unnoetig seit dem refactoring, glaube ich.
    # item.quantity-=quantity #deletes original item

    @@holder.delete(self) #closes the holding-state

  end

  #moves the item from seller to holding
  def self.shipItem(item, seller, buyer, quantity)
    item_list = Models::Item.get_item_list
    item_list.delete(item)

    buyer.credits -= Integer(item.price)*quantity

    index = seller.item_list.index(item)
    #seller: remove number of items (or item)
    if (seller.item_list[index].quantity == quantity)
      seller.item_list.delete(item)
    else
      seller.item_list[index].quantity -= quantity
    end

    holding = self.created(item,seller,buyer,quantity)
  end

end
end