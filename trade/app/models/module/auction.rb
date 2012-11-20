module Models
  class Auction
    require 'require_relative'
    require_relative('item')
    attr_accessor :item, :owner, :increment, :min_price, :end_time, :bids, :current_winner, :current_selling_price
    # [String]: Stores all error messages
    attr_accessor :errors

    @@auctions = Array.new

    def self.create(owner, item, increment, min_price, end_time)
      Auction.new(owner, item, increment.to_i, min_price.to_i, end_time)
    end

    def self.auctions_by_user(user)
       return @@auctions.select { |auction| auction.owner == user}
    end

    def self.auction_by_item(item)
      return @@auctions.detect { |auction| auction.item == item}
    end

    def initialize(owner, item, increment, min_price, end_time)
      self.item= item
      self.owner= owner
      self.increment= increment
      self.min_price= min_price
      self.end_time= end_time
      self.current_selling_price = 0
      @editable = true
      @bids = Hash.new(0)
    end

    # Saves the auction to the Auction-List
    def save
      raise "Duplicated item" if Auction.auction_by_item(item)
      @@auctions << self
      puts "added an auction"
    end

    # Controls the auctions's data and adds errors if necessary.
    # - @return: true if there is no invalid data or false if there is.
    def is_valid?
      self.errors = ""
      self.errors += "Select a valid End-Date for your auction.\n" unless Time.now < self.end_time
      self.errors += "Select a valid increment.\n" unless Item.valid_integer?(self.increment)
      self.errors += "Select a valid minimal price.\n" unless Item.valid_integer?(self.min_price)
      #self.errors += "An auction for this item already exists. \n" unless Auction.auction_by_item(item)
      self.errors != "" ? false : true
    end

    def place_bid(bidder, bid)
      return :not_enough_credits if bidder.credits < bid - @bids[bidder]
      return :invalid_bid unless self.valid_bid?(bidder, bid)
      return :bid_already_made if @bids.values.detect { |b| b==bid }
      update_current_winner(bidder, bid)
      @editable = false
      return :success
    end

    def self.all_auctions(options = {})
      o = {
          :order_by => 'name',
          :order_direction => 'asc'
      }.merge(options)
      if o[:order_direction] == 'asc'
        return @@auctions.sort{ |a,b| a.send(o[:order_by]) <=> b.send(o[:order_by]) }
      else
        return @@auctions.sort{ |a,b| b.send(o[:order_by]) <=> a.send(o[:order_by]) }
      end
    end

    def self.clear_all
      @@auctions = []
    end

    def valid_bid?(bidder, bid)
      if @current_selling_price == 0
        return bid >= self.min_price
      else
        return @bids[bidder] < bid && bid >= @current_selling_price
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
            Mailer.new_winner(old_winner, self)
          end
          @bids[new_bidder] = bid
          @current_winner.credits -= @bids[@current_winner] #SH Deduct the money from the current winner
          if (@current_selling_price > 0)
            @current_selling_price = @bids[old_winner] + self.increment
          else
            @current_selling_price = self.min_price
          end

        end
      end
    end

    def over?
      Time.now > self.end_time
    end

    def end_auction

      if @current_winner == nil
        @@auctions.delete(self)
        # RB: Adding the item back to the list first, makes it possible to buy it with normal process.
        self.owner.item_list.push(self.item)    # TODO: Not just pushing the item to the list, but merge it with eventually existing items. (like with buying items)
      else
        self.item.price = @current_selling_price
        @current_winner.credits += @bids[@current_winner]
        self.owner.item_list.push(self.item)
        @current_winner.buy_new_item(item,1)

        Mailer.bid_over(@current_winner.e_mail, self)
      end

    end
  end
end
