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

  enable :sessions
  #session['user'] = nil
  #session['auth'] = false
  set :views, relative('app/views')
  use Controllers::Authentication
  use Controllers::Sites
  use Controllers::Creator

  get '/hi' do
    "Hello World"
  end


end

end

