require 'test/unit'
require 'rubygems'
require 'require_relative'
require_relative('../app/models/module/user')
require_relative('../app/models/module/item')
require_relative('../app/models/module/comment')
require_relative('../app/models/module/auction')

include Models

class AuctionTest < Test::Unit::TestCase
  def setup
    User.clear_all
    @userA = User.created("Hans", "hansli", "bla@mail.com")
    @userB = User.created("Horst", "horstli", "bla1@mail.com")
    @userC = User.created("Vreni", "vreneli", "bla2@mail.com")
    @userD = User.created("Penner", "pennerli", "bla3@mail.com")
    @userA.credits = 1000
    @userB.credits = 1000
    @userC.credits = 1000
    @userD.credits = 1
  end

  def teardown
    User.clear_all
  end

  def test_canBid
    initialPrice = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = @userA.create_item(item_name, initialPrice, 1)
    auction = Auction.create(@userA, item, increment, initialPrice, 0)
    assert(!auction.valid_bid?(@userD,1)) # bid not high enough
    assert(!auction.valid_bid?(@userD,2)) # not enough money

    assert(!auction.valid_bid?(@userA,4)) # bid not high enough
    assert(auction.valid_bid?(@userA,5))  # bid high enough & enough money
  end

  def test_createAuction
    initialPrice = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = @userA.create_item(item_name, initialPrice, 1)
    auction = Auction.create(@userA, item, increment, initialPrice, 0)

    assert(auction.owner == @userA)
    assert(auction.current_selling_price == 0)

    assert(auction.valid_bid?(@userB, 10))

    ###### FIRST BID :: Price = nil
    auction.place_bid(@userB, 10)
    ### AFTER :: Bidders = [10], Price = 5
    assert(auction.current_selling_price == 5)

    assert(!auction.valid_bid?(@userC, 3))
    assert(!auction.valid_bid?(@userC, 4))
    assert(auction.valid_bid?(@userC, 5))

    ###### SECOND BID :: Price = 5, Minimal Bid = 5 ######
    auction.place_bid(@userC, 5)
    ### AFTER :: Bidders = [5, 10], Price = 7
    assert(auction.current_selling_price == 7)

    assert(!auction.valid_bid?(@userC, 5))
    assert(!auction.valid_bid?(@userC, 6))
    assert(auction.valid_bid?(@userC, 7))

    ###### THIRD BID :: Price = 7, Minimal Bid = 7 ######
    auction.place_bid(@userC, 7)
    ### AFTER :: Bidders = [7, 10], Price = 9

    assert(auction.current_selling_price == 9)
  end

  def test_current_winner
    initialPrice = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = @userA.create_item(item_name, initialPrice, 1)
    auction = Auction.create(@userA, item, increment, initialPrice, 0)

    assert auction.current_winner == nil
    auction.place_bid(@userB, 10)
    assert auction.current_winner == @userB
    auction.place_bid(@userC, 15)
    assert auction.current_winner == @userC
  end

  def test_get_money_back_if_overbidden
    initialPrice = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = @userA.create_item(item_name, initialPrice, 1)
    auction = Auction.create(@userA, item, increment, initialPrice, 0)

    auction.place_bid(@userB,20)
    assert auction.current_selling_price == 5
    assert @userA.credits == 1000
    assert @userB.credits == 980
    assert @userC.credits == 1000
    auction.place_bid(@userC,15)
    assert auction.current_selling_price == 17
    assert @userA.credits == 1000
    assert @userB.credits == 1000
    assert @userC.credits == 995
    auction.place_bid(@userC,25)
    assert auction.current_selling_price == 22
    assert @userA.credits == 1000
    assert @userB.credits == 1000
    assert @userC.credits == 975
  end

  def test_cant_edit_after_bidding
    initialPrice = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = @userA.create_item(item_name, initialPrice, 1)
    auction = Auction.create(@userA, item, increment, initialPrice, 0)

    assert auction.editable?
    auction.place_bid(@userB, 20)
    assert !auction.editable?
  end

  def test_finish_transaction
    initialPrice = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = @userA.create_item(item_name, initialPrice, 1)
    auction = Auction.create(@userA, item, increment, initialPrice, 0)

    auction.place_bid(@userB,20)
    auction.place_bid(@userC,15)
    auction.place_bid(@userC,25)
    auction.place_bid(@userC,30)
    assert @userA.credits == 1000
    assert @userB.credits == 1000
    assert @userC.credits == 970

    auction.end

    assert @userA.credits == 1022
    assert @userB.credits == 1000
    assert @userC.credits == 978
  end

  def test_finish_transaction_no_bidder
    initialPrice = 5
    increment = 2
    item_name = "TestItem"             #(name, price, owner, increment, endTime, description = "")
    item = @userA.create_item(item_name, initialPrice, 1)
    auction = Auction.create(@userA, item, increment, initialPrice, 0)

    auction.end
    assert @userA.credits == 1000
  end
end