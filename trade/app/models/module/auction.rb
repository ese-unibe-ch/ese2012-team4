module Models
  class Auction
    attr_accessor :item, :owner, :increment, :min_prize, :end_time, :bids



    def self.create(owner, item, increment, min_prize, end_time)
      self.item= item
      self.owner= owner
      self.increment= increment
      self.min_prize= min_prize
      self.end_time= end_time
      @bids = Hash.new()
    end

    def place_bid(owner, price)
      return :invaliv_bid if @bids[owner] > price or price <= self.min_prize
      return :bid_already_made if @bids.values.detect {|bid| bid==price}
      @bids[owner] = price
      return :success
    end
  end
end
