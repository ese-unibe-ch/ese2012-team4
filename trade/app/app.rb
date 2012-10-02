def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'rubygems'
require 'require_relative'
require 'sinatra'
require 'haml'
require_relative('controllers/authentication')
require_relative('controllers/sites')

module App
class App #< Sinatra::Base

  enable :sessions
  set :views, relative('app/views')
  use Controllers::Authentication
  use Controllers::Sites

  get '/' do
    "Hello World"
  end


end

end

