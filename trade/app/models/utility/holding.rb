module Models
class Holding
  @@holder = {}

  attr_accessor :item, :seller, :buyer, :quantity

  def self.created (item, seller, buyer, quantity)
    holding = self.new

    holding.item = item
    holding.seller = seller
    holding.buyer = buyer
    holding.quantity = quantity

    @@holder.push(holding)
  end

  #moves Money after receiving & moves the item to buyers stack
  def itemReceived
    seller.credits+=Integer(item.price)*quantity

    #if(item.quantity.to_i == quantity)
      item.owner = buyer
      item.owner.remove_item(item)
      if !(identical = buyer.list_items_inactive.detect{|i| i.name== item.name and i.price == item.price and i.description==item.description}).nil?
        identical.quantity+=quantity
      else
        buyer.item_list.push(item)
      end

    item.quantity-=quantity #deletes original item

    @@holder.delete(self) #closes the holding-state

  end

  #moves the item from seller to holding
  def self.shipItem(item, seller, buyer, quantity)


    buyer.credits -= Integer(item.price)*quantity

    #seller: remove number of items (or item)
    if (seller.item_list["#{item.id}"].quantity == quantity)
      seller.item_list.delete(item)
    else
      seller.item_list["#{item.id}"].quantity -= quantity
    end

    item.active = false

    holding = self.created(item,seller,buyer,quantity)
    item.owner = holding
  end

end
end