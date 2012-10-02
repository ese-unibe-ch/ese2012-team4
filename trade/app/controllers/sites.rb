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
      if session['auth']
        redirect "/home"
      else
        haml :index
      end
    end

    get '/login' do
      if session['auth']
        redirect "/home"
      else
        haml :login
      end
    end

    get '/logout' do
      if session['auth']
        haml :logout
      else
        redirect "/"
      end
    end

    get '/home' do
      if session['auth']
        haml :home
      else
        redirect "/"
      end
    end

    get '/home/active' do
      if session['auth']
        user = session['user']
        haml :home_active, :locals => {:active_items => User.get_user(user).list_items}
      else
        redirect "/"
      end
    end

    get '/home/inactive' do
      if session['auth']
        user = session['user']
        haml :home_inactive, :locals => {:inactive_items => User.get_user(user).list_items_inactive}
      else
        redirect "/"
      end
    end

    get '/home/new' do
      if session['auth']
        haml :home_new
      else
        redirect "/"
      end
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