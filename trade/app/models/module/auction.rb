module Models
  class Auction
    attr_accessor :item, :owner, :increment, :min_prize, :end_time, :bids, :current_winner, :current_selling_price

    def self.create(owner, item, increment, min_prize, end_time)
      self.item= item
      self.owner= owner
      self.increment= increment
      self.min_prize= min_prize
      self.end_time= end_time
      self.current_selling_price = price + increment
      @bids = Hash.new(-10000)
    end

    def place_bid(owner, price)
      return :not_enough_credits if owner.credits < price
      return :invalid_bid if @bids[owner] > price or price <= @current_selling_price
      return :bid_already_made if @bids.values.detect { |bid| bid==price }
      @bids[owner] = price
      update_current_winner(owner)
      return :success
    end

    def update_current_winner(new_bidder)

      if @bids[new_bidder] > @bids[current_winner]
        old_winner = @current_winner
        @current_winner = new_bidder
        old_winner.credits += @bids[old_winner] #SH Gives the money of the previous winner back

        Mailer.new_winner(old_winner, self)

        @current_winner.credits -= @bids[@current_winner] #SH Deduct the money from the current winner
        @current_selling_price = @bids[old_winner] + increment
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