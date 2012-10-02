def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'rubygems'
require 'require_relative'
require 'sinatra/base'
require 'haml'
require 'sinatra/content_for'
require_relative('../models/module/user')

include Models

module Controllers
  class Sites < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor

    get '/' do
      haml :index
    end

    get '/login' do
      haml :login
    end

    get '/logout' do
      haml :logout
    end

    get '/home' do
      haml :home
    end

    get '/users' do
      haml :users
    end

    get '/users/:id' do
      haml :users_id
    end

    get '/items' do
      haml :items
    end

    get '/items/:id' do
      haml :items_id
    end

  end
end