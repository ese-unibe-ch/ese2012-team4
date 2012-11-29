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
      self.current_selling_price = min_price
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
      item.quantity = 1
      self.quantity = item.quantity
      self.auction = true
    end


    # @Override
    # - @return [Array]: the auctions in the system, not belonging to the viewer and sorted as indicated in options
    def self.get_all(viewer = nil, options = {})
      all_array = Offer.get_all(viewer, options)
      ret =  all_array.select{|s| s.auction}
      ret
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
      return true if @current_winner==nil and bid>=min_price
      return @bids[bidder] < bid && bid >= @current_selling_price+self.increment
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
        if bid > @bids[@current_winner] and bid > @current_selling_price
          old_winner = @current_winner
          @current_winner = new_bidder
          unless old_winner.nil?
            old_winner.credits += @bids[old_winner] #SH Gives the money of the previous winner back
            Mailer.new_winner(old_winner.e_mail, self)
          end
          @bids[new_bidder] = bid
          @current_winner.credits -= @bids[@current_winner] #SH Deduct the money from the current winner
          if (!old_winner.nil?)
            if @bids[old_winner]+increment <= bid
              @current_selling_price = @bids[old_winner] + self.increment
            else
              @current_selling_price = @bids[current_winner]
            end
          else
            @current_selling_price = bid
          end
        else
          #if the bid is below the maximal bid + increment
          if bid < @bids[current_winner]-increment
            @current_selling_price = bid + increment
          elsif bid < @bids[@current_winner] and bid > @bids[@current_winner] - increment
            @current_selling_price = bid  # GM : TODO: How to handle the case where winning bid = 100 , bid = 99 and increment = 5?
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

      if bids.length!=0
        @current_winner.credits += bids[@current_winner]

          self.item.price = @current_selling_price
        @current_winner.buy_new_item(self.item,1, @current_winner)
        Mailer.bid_over(@current_winner.e_mail, self)
      else
        self.item.deactivate
        self.owner.add_offer(self.item)
      end
    end
  end
end

