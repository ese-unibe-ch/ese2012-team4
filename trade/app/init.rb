def relative path
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'rubygems'
require 'require_relative'
require_relative('../../trade/app/models/module/item')
require_relative('../../trade/app/models/module/user')

include Models

userA = Models::User.created( "userA", "passwordA" )
userA.save
aa = userA.create_item("UserA_ItemA", 10)
ab = userA.create_item("UserA_ItemB", 50)
ab.active = true
ac = userA.create_item("UserA_ItemC", 120)
ac.active = true

userB = Models::User.created( "userB", "passwordB" )
userB.save
ba = userB.create_item("UserB_ItemA", 10)
ba.active = true
bb = userB.create_item("UserB_ItemB", 50)
bb.active = true
bc = userB.create_item("UserB_ItemC", 120)

userC = Models::User.created( "userC", "passwordC" )
userC.save
ca = userC.create_item("UserC_ItemA", 10)
ca.active = true
cb = userC.create_item("UserC_ItemB", 50)
cc = userC.create_item("UserC_ItemC", 120)
cc.active = true

ese = Models::User.created( "ese", "ese" )
ese.save