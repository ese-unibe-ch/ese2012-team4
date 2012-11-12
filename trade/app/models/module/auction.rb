module Models
  class Auction
    attr_accessor :item, :owner, :increment, :min_prize, :end_time, :bids, :current_winner



    def self.create(owner, item, increment, min_prize, end_time)
      self.item= item
      self.owner= owner
      self.increment= increment
      self.min_prize= min_prize
      self.end_time= end_time
      @bids = Hash.new(-10000)
    end

    def place_bid(owner, price)
      return :invalid_bid if @bids[owner] > price or price <= self.min_prize
      return :bid_already_made if @bids.values.detect {|bid| bid==price}
      @bids[owner] = price
      update_current_winner
      return :success
    end

    def update_current_winner
      temp_winner = nil
      @bids.each{ |owner, price|  if @bids[temp_winner] < price
                                    temp_winner = owner
                                  end
      }
      @current_winner = temp_winner
    end
  end
end
