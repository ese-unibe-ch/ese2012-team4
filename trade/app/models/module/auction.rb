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
      @bids = Hash.new(min_price - increment)
      @@auctions << self
      puts "added an auction"
    end

    def place_bid(bidder, bid)
      return :not_enough_credits if bidder.credits < bid
      return :invalid_bid if @bids[bidder] > bid or bid <= @current_selling_price
      return :bid_already_made if @bids.values.detect { |b| b==bid }
      update_current_winner(bidder, bid)
      @editable = false
      return :success
    end

    def editable?
      @editable
    end

    def update_current_winner(new_bidder, bid)

      if bid > @bids[@current_winner]
        old_winner = @current_winner
        @current_winner = new_bidder
        unless old_winner.nil?
          old_winner.credits += @bids[old_winner] #SH Gives the money of the previous winner back
          #Mailer.new_winner(old_winner, self)
        end
        @current_selling_price = @bids[old_winner] + increment
        @bids[new_bidder] = bid
        @current_winner.credits -= @bids[@current_winner] #SH Deduct the money from the current winner
      end
    end

    def end_auction
      unless @current_winner == nil
        @item.owner = @current_winner
        @owner.credits += @current_selling_price
        @current_winner.credits += @bids[@current_winner] - @current_selling_price
        Mailer.bid_over(@current_winner, self)
      end
    end
  end
end
