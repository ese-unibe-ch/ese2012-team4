module Models
  class Auction
    attr_accessor :item, :owner, :increment, :min_prize, :end_time

    def self.create(owner, item, increment, min_prize, end_time)
      self.item= item
      self.owner= owner
      self.increment= increment
      self.min_prize= min_prize
      self.end_time= end_time
    end

  end
end
