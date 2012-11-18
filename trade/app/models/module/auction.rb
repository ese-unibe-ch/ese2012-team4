module Models
  class Auction
    attr_accessor :item, :owner, :increment, :min_price, :end_time, :bids, :current_winner, :current_selling_price

    @@auctions = Array.new

    def self.create(owner, item, increment, min_price, end_time)
      Auction.new(owner, item, increment, min_price, end_time)
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
      @@auctions << self
      puts "added an auction"
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
      unless @current_winner == nil
        @item.owner = @current_winner
        @owner.credits += @current_selling_price
        @current_winner.credits += @bids[@current_winner] - @current_selling_price
        Mailer.bid_over(@current_winner, self)
      end
      @@auctions.delete(self)
    end
  end
end
