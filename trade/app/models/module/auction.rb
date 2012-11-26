module Models
  require 'require_relative'
  require_relative('item')
  require_relative('offer')
  class Auction < Offer

    attr_accessor :item, :increment, :min_price, :bids, :current_winner, :current_selling_price
    # [String]: Stores all error messages


    def self.create(item, increment, min_price, end_time)
      Auction.new(item, increment.to_i, min_price.to_i, end_time)
    end

    def initialize(item, increment, min_price, end_time)
      self.item= item
      self.min_price= min_price
      @bids = Hash.new(0)
      @editable = true
      self.current_selling_price = 0
      self.name = item.name
      self.owner= item.owner
      self.id = item.id
      self.description = item.description
      self.expiration_date= end_time
      self.timestamp = item.timestamp
      self.increment= increment
      self.head_comments = item.head_comments
      self.wishlist_users = item.wishlist_users
      self.image = item.image
      self.quantity = item.quantity
      self.auction = true
    end


    # Controls the auctions's data and adds errors if necessary.
    # - @return: true if there is no invalid data or false if there is.
    def is_valid?
      self.errors = ""
      self.errors += "Select a valid End-Date for your auction.\n" unless Time.now < self.expiration_date
      self.errors += "Select a valid increment.\n" unless Item.valid_integer?(self.increment)
      self.errors += "Select a valid minimal price.\n" unless Item.valid_integer?(self.min_price)
      #self.errors += "An auction for this item already exists. \n" unless Auction.auction_by_item(item)
      self.errors != "" ? false : true
    end

    def is_active?
      true
    end

    def place_bid(bidder, bid)
      return :not_enough_credits if bidder.credits < bid - @bids[bidder]
      return :invalid_bid unless self.valid_bid?(bidder, bid)
      return :bid_already_made if @bids.values.detect { |b| b==bid }
      update_current_winner(bidder, bid)
      @editable = false
      return :success
    end

    def self.clear_all
      @@offers = []
    end

    def valid_bid?(bidder, bid)
      if @current_selling_price == 0
        return bid >= self.min_price
      else
        return @bids[bidder] < bid && bid >= @current_selling_price+self.increment #RB: changed from without increment
      end
    end

    def name
      self.item.name
    end

    def price
      @current_selling_price
    end

    def seller_rating
      self.owner.rating
    end

    def editable?
      @editable
    end



    # different Cases, how we update the price and winner:
    # 1. The bid is from the winner --> reserves credits and adds your bid, no changes on the price
    # 2. bid > old highest, curent price+ increment and  --> the winner changes, price is
    # 3.
    # 3.
    def update_current_winner(new_bidder, bid)

      # if you are overbidding yourself...
      if @current_winner == new_bidder
        new_bidder.credits -= bid - @bids[new_bidder]
        @bids[new_bidder] = bid
        # no need to change the current selling price
      else
        if bid > @bids[@current_winner]
          old_winner = @current_winner
          @current_winner = new_bidder
          unless old_winner.nil?
            old_winner.credits += @bids[old_winner] #SH Gives the money of the previous winner back
            Mailer.new_winner(old_winner.e_mail, self)
          end
          @bids[new_bidder] = bid
          @current_winner.credits -= @bids[@current_winner] #SH Deduct the money from the current winner
          if (@current_selling_price > 0)
            if @bids[old_winner]+increment <= bid
              @current_selling_price = @bids[old_winner] + self.increment
            else
              @current_selling_price = @bids[current_winner]
            end
          else
            @current_selling_price = self.min_price
          end
        else
          #if the bid is below the maximal bid + increment
          if bid < @bids[current_winner]

            @current_selling_price = bid
          else

          end
        end

      end
    end



    def deactivate
      # TODO: Not just pushing the item to the list, but merge it with eventually existing items. (like with buying items)
      self.owner.remove_offer(self)
      self.owner.add_offer(self.item)
      @@offers.delete(self)
      @@offers["#{self.id}"]=self.item

    end


    def end
      # RB: needs to be done first, because the scheduler has to stop finding it
      self.owner.remove_offer(self)
      @@offers.delete(self)
      @@offers["#{self.id}"]=self.item

      unless @current_selling_price == 0
        @current_winner.credits += bids[@current_winner]
        unless @current_winner == nil
          self.item.price = @current_selling_price
          @current_winner.buy_new_item(self.item,1)
          Mailer.bid_over(@current_winner.e_mail, self)
        end
      end
    end
  end
end
