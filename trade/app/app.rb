def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'rubygems'
require 'require_relative'
require 'sinatra'
require 'haml'
require_relative('controllers/not_authenticated')
require_relative('controllers/item_control')
require_relative('controllers/user_control')
require_relative('controllers/comment_control')

require_relative('../../trade/app/models/module/item')
require_relative('../../trade/app/models/module/user')

include Models
include Controllers

class App < Sinatra::Base

  use Not_authenticated
  use ItemControl
  use CommentControl
  use UserControl

  enable :sessions
  enable :method_override
  set :views, relative('app/views')
  set :public_folder, relative('public')

  configure :development do
    userA = User.created( "Evil Simu", "password1", "e_mail_A@preset.com", "Music by Nino Rota" )
    userA.save
    userA.image = FileUtils::pwd+"/public/images/user_pix/shirsbrunner2.jpeg"
    aa = userA.create_item("Half-empty hair wax", 15, 1)
    ab = userA.create_item("Vespa Primavera ET3", 250, 1)
    ab.description = "Rusty, but a true classic"
    ab.active = true
    ac = userA.create_item("Beretta Model 38/42", 60, 1)
    ac.description = "Cheap, but only used once in family-business"
    ac.active = true

    for i in 0..10
     userA.add_rating(rand(5))
    end

    co = ac.comment(userA, "Great Item! Please buy it!")



    userB = User.created( "Evil Giänu", "password1", "e_mail_B@preset.com" )
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

    userC = User.created( "Evil Lüku", "password1", "e_mail_C@preset.com" )
    userC.save
    userC.image = FileUtils::pwd+"/public/images/user_pix/ld_baaad.jpg"
    ca = userC.create_item("Rusty saber", 70, 1)
    ca.description="YAAAAAAAAAAAAAAARRRRRRRRRRRRR!!!"
    ca.active = true
    cb = userC.create_item("Cheap rum", 10, 5)
    cb.description = "Smells and tastes like a rotten fish, but it gets you wonderfully drunk"
    cc = userC.create_item("Ship", 2700, 1)
    cc.description = "It's a bloody ship, mate! YAAAAARRRRRRR!!"
    cc.active = true
    co.answer(userC, "You're right, those things will scare my rum off my ship!")

    for i in 0..10
      userC.add_rating(rand(5))
    end

    ese = User.created( "ese", "ese", "ese@preset.com", "fancy code-snippets" )
    ese.save
    ese.image = FileUtils::pwd+"/public/images/user_pix/ese.jpeg"

    for i in 0..10
      ese.add_rating(4)
    end

    userS = User.created( "Сиимон", "password1", "e_mail_A@preset.ru", "И доньт реаллы спеак руссиан" )
    userS.save
    userS.image = FileUtils::pwd+"/public/images/user_pix/shirsbrunner1.jpg"
    sa = userS.create_item("Warm cap, siberian standard", 15, 149)
    sb = userS.create_item("Creditcard-Data", 5, 10540)
    sc = userS.create_item("Uranium-ore", 10000000, 1)
    sa.description = "Cozy, good for harsh winters"
    sa.active = true
    sb.description = "First come first serve"
    sb.active = true
    sc.description = "Only for qualified buyers"

    for i in 0..10
      userA.add_rating(rand(5))
    end

    co = ac.comment(userA, "Great Item! Please buy it!")

    end

  end

App.run!