def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'rubygems'
require 'require_relative'
require 'sinatra'
require 'haml'
require_relative('controllers/authentication')
require_relative('controllers/sites')
require_relative('controllers/creator')

module App
class App #< Sinatra::Base

  userA = Models::User.created( "user", "password" )
  userA.save
  userB = Models::User.created( "userB", "passwordB" )
  userB.save

  enable :sessions
  set :views, relative('app/views')
  set :public_folder, 'public'
  set :static, true
  set :public, 'public'
  use Controllers::Authentication
  use Controllers::Sites
  use Controllers::Creator

  get '/hi' do
    "Hello World"
  end


end

end

