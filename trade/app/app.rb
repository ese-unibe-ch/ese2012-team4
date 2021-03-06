# encoding: utf-8
def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'rubygems'
require 'require_relative'
require 'sinatra'
require 'haml'
require 'rufus-scheduler'
require_relative('controllers/not_authenticated')
require_relative('controllers/item_control')
require_relative('controllers/trader_control')
require_relative('controllers/comment_control')
require_relative('controllers/auction_control')
require_relative('controllers/message_control')
require_relative('controllers/category_control')

require_relative('../../trade/app/models/module/item')
require_relative('../../trade/app/models/module/user')
require_relative('../../trade/app/models/module/offer')
require_relative('../../trade/app/models/module/category')
require_relative('../../trade/app/models/module/organization')


include Models
include Controllers

class App < Sinatra::Base

  use Not_authenticated
  use ItemControl
  use CommentControl
  use TraderControl
  use AuctionControl
  use MessageControl
  use CategoryControl

  enable :sessions
  enable :method_override
  set :views, relative('app/views')
  set :public_folder, relative('public')

  configure :development do
    userA = User.created( "Don Simon", "password1", "e_mail_A@preset.com", "Music by Nino Rota" )
    userA.save
    userA.image = FileUtils::pwd+"/public/images/user_pix/shirsbrunner2.jpeg"
    aa = userA.create_item("Half-empty hair wax", 15, 1)
    ab = userA.create_item("Vespa Primavera ET3", 250, 1)
    ac = userA.create_item("Borsalino", 60, 1)
    ad = userA.create_item("Red roses", 1, 20)

    aa.description = "My favourite brand (but got short hair now)"
    ab.description = "Rusty, but a true classic"
    ac.description = "My old hat, great for family-business"
    ad.description = "Always a great gift"

    aa.active = true
    ab.active = true
    ac.active = true
    ad.active = true

    aa.image = FileUtils::pwd+"/public/images/item_pix/Murrays.jpg"
    ab.image = FileUtils::pwd+"/public/images/item_pix/Vespa.jpg"
    ac.image = FileUtils::pwd+"/public/images/item_pix/Borsalino.jpg"
    ad.image = FileUtils::pwd+"/public/images/item_pix/rose.jpg"

    for i in 0..10
      userA.add_rating(rand(4)+1)
    end

    co = ac.comment(userA, "Great Item! Please buy it!")



    userB = User.created( "sleazy Giänu", "password1", "e_mail_B@preset.com", "I like dark alleys and the smell of chloroform" )
    userB.save
    userB.image = FileUtils::pwd+"/public/images/user_pix/gl2.jpg"
    ba = userB.create_item("Black leather suitcase", 10, 2)
    ba.active = true
    ba.description = "Crappy, but stylish"
    bb = userB.create_item("Dirty Socks", 5, 10)
    bb.active = true
    bb.description = "Too lazy to wash, I'm buying new ones"
    co.answer(userB, "It doesn't seems that great. That model is quite loud, can't you go any lower than that?")

    for i in 0..10
      userB.add_rating(rand(5))
    end

    userG = User.created( "Giänu", "password1", "e_mail_B@preset.com", "Fan of all the good stuff" )
    userG.save
    userG.image = FileUtils::pwd+"/public/images/user_pix/gl1.jpg"
    ga = userG.create_item("Green Sweater", 45, 1)
    ga.active = true
    ga.image = FileUtils::pwd+"/public/images/item_pix/sweater.jpg"
    ga.description = "Warm, stylish, represents the very best of men's clothing culture"
    gb = userG.create_item("Purple Wig", 25, 1)
    gb.image = FileUtils::pwd+"/public/images/item_pix/wig.jpg"
    gb.active = true
    gb.description = "No longer needed, top condition though."

    for i in 0..10
      userG.add_rating(rand(5))
    end

    userC = User.created( "Evil Lüku", "password1", "e_mail_C@preset.com", "Buy or die! I got some hungrray sharks!" )
    userC.save
    userC.image = FileUtils::pwd+"/public/images/user_pix/ld_baaad.jpg"
    ca = userC.create_item("Rusty saber", 70, 1)
    ca.description="Cuts coconuts and throats. Although, coconuts be sometimes too hard."
    ca.active = true
    ca.image = FileUtils::pwd+"/public/images/item_pix/saber.jpg"
    cb = userC.create_item("Cheap rum", 10, 5)
    cb.description = "Smells and tastes like a rot' fish, but it gets you wonderfully splice t' mainbrace."
    cc = userC.create_item("Ship", 2700, 1)
    cc.description = "It's a bloody ship, mate! Has cannons, a jail aaand a kitchen! Crew not included, they're all dead. YAAAAARRRRRRR!!"
    cc.active = true
    cc.image = FileUtils::pwd+"/public/images/item_pix/pirateship.jpg"
    co.answer(userC, "You're right, those things will scare my rum off my ship!")
    cd = userC.create_item("Replica flag *BEST BUY* ocean-proof SHorT t1mE!!!", 70, 1)
    cd.description="This be a very genuine flag. It makes everody fear you. Made in Bangladesh."
    cd.active = true
    cd.image = FileUtils::pwd+"/public/images/item_pix/flag.png"

    for i in 0..10
      userC.add_rating(rand(5))
    end

    userD = User.created( "Smoky Remo", "password1", "e_mail_D@preset.com", "Wanna try?" )
    userD.save
    userD.image = FileUtils::pwd+"/public/images/user_pix/Remo2.jpg"
    da = userD.create_item("Massive Shisha", 90, 1)
    da.description="Very good quality Waterpipe, as they told me in Egypt. You will have tons of smoke!"
    da.active = true
    da.image = FileUtils::pwd+"/public/images/item_pix/Shisha.jpg"
    db = userC.create_item("Cherry Tabacco", 20, 10)
    db.description = "Best flavor in town!"
    dbc = db.comment(userB, "I don't like it at all, sorry but can't you offer some good one?")

    for i in 0..10
      userD.add_rating(rand(4)+1)
    end

    userE = User.created( "Remo", "password1", "remo_burn@hotmail.com", "-nice hardware\n-movies" )
    userE.save
    userE.image = FileUtils::pwd+"/public/images/user_pix/Remo1.jpg"
    ea = userE.create_item("The Lord of The Rings, The Return of the King DVD", 5, 1)
    ea.description = "2 DVD Pack, no scratches!"
    ea.image = FileUtils::pwd+"/public/images/item_pix/LOTR.jpg"
    ab = userE.create_item("Big Yacht", 200, 1)
    ab.active = true
    ab.description = "This ship is just attracting attention, everywhere you sail."

    for i in 0..10
      userE.add_rating(rand(4)+1)
    end

    ese = User.created( "ese", "ese", "ese@preset.com", "fancy code-snippets" )
    ese.save
    ese.image = FileUtils::pwd+"/public/images/user_pix/ese.jpeg"
    gtg = ese.create_item("A guide to git", 20, 200, "Everything you should know but somehow didn't learn in P2")
    Auction.create(gtg, 5, 20, TimeHandler.parseTime("2012-11-29", ""))
    gtg.image = FileUtils::pwd+"/public/images/item_pix/git.jpg"

    org = Organization.created( "Coding Inc.", ese)
    org.save


    for i in 0..10
      ese.add_rating(4)
    end

    userS = User.created( "Сиимон", "password1", "e_mail_A@preset.ru", "И доньт реаллы спеак руссиан" )
    userS.save
    userS.image = FileUtils::pwd+"/public/images/user_pix/shirsbrunner1.jpg"
    sa = userS.create_item("Warm cap, siberian standard, military grade", 15, 149)
    sa.image = FileUtils::pwd+"/public/images/item_pix/Pelzmutze.jpg"
    sb = userS.create_item("Creditcard-Data", 5, 10540)
    sb.image = FileUtils::pwd+"/public/images/item_pix/Card-Data.jpg"
    sc = userS.create_item("Uranium-ore", 10000000, 1)
    sc.image = FileUtils::pwd+"/public/images/item_pix/Uranium_ore.jpg"
    sa.description = "Cozy, good for harsh winters"
    sa.active = true
    sb.description = "First come first serve"
    sb.active = true
    sc.description = "Only for qualified buyers"
    sc.active = true

    for i in 0..10
      userS.add_rating(rand(3))
    end

    co = ac.comment(userA, "Great Item! Please buy it!")

    crazy_misch = User.created("Misch", "misch1", "misch.wyss@hotmail.com", "If it tastes good, I'll take it!")
    crazy_misch.save
    crazy_misch.image = FileUtils::pwd+"/public/images/user_pix/crazy_misch.jpg"

    good_misch = User.created("Good Misch", "misch2", "misch@preset.com", "I love all your Itemmmsssss! Shopping!")
    good_misch.save
    good_misch.image = FileUtils::pwd+"/public/images/user_pix/good_misch.jpg"


    userF = User.created( "Evil Bensch", "password1", "e_mail_D@preset.com")
    userF.save
    userF.image = FileUtils::pwd+"/public/images/user_pix/Bensch1.JPG"
    fa = userF.create_item("Cannon Ball", 20, 10)
    fa.image = FileUtils::pwd+"/public/images/item_pix/Cannonball.jpg"
    fa.active = true
    fb = userF.create_item("Brand New Bike", 50, 1)
    fb.image = FileUtils::pwd+"/public/images/item_pix/OldBike.jpeg"
    fb.description = "Has a nice colour and is in great condition. \n
                      Come by and take it for a test ride."
    fb.active = true
    for i in 0..10
      userF.add_rating(rand(5))
    end

    userG = User.created( "Bensch", "password1", "e_mail_E@preset.com")
    userG.save
    userG.image = FileUtils::pwd+"/public/images/user_pix/Bensch2.jpg"
    ga = userG.create_item("St. Peter's Basilica", 500, 1)
    ga.image = FileUtils::pwd+"/public/images/item_pix/StPeters.JPG"
    ga.description = "Very nice and big building. \n
                      Special price, only for a short time! \n
                      Has to be picked up by buyer!"
    ga.active = true
    gb = userG.create_item("Dessert", 5, 100)
    gb.image = FileUtils::pwd+"/public/images/item_pix/Dessert.JPG"
    gb.description = "DIG IN!!!"
    gb.active = true

    for i in 0..10
      userG.add_rating(rand(4))
    end

    orgA = Organization.created("OrgA", userG)
    orgA.save


    #some initial categories
    sup = Category.get_supercategory
    cars = Category.new("Cars")
    sup.add(cars)
    ships = Category.new("Ships")
    sup.add(ships)
    pirate_ships = Category.new("Pirateships")
    ships.add(pirate_ships)
    cc.category = pirate_ships
    ab.category = ships

    scheduler = Rufus::Scheduler.start_new

    scheduler.every '500' do
      for auction in Offer.get_all
        if auction.expired?
          auction.end
          puts "ended auction for #{auction.item.name}"
        end
      end
      for item in Item.get_all("")
        if item.expired?
          item.owner.deactivate_item(item.id)
        end
      end
    end

  end

  end

App.run!
