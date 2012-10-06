def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'rubygems'
require 'require_relative'
require 'sinatra/base'
require 'haml'
require 'sinatra/content_for'
require_relative('../models/module/user')
require_relative('../models/module/item')

include Models

module Controllers
  class Creator < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor

    post '/create' do
      if session['auth']
        user = session['user']
        begin
          User.get_user(user).create_item(params[:name], Integer(params[:price]))
          # MW: maybe "User.by_name" might be somewhat more understandable
        rescue
          redirect "/error/Not_A_Number"
        end
        redirect "/home/inactive"
      else
        redirect "/"
      end
    end

    post '/edit_item' do
      ## To do!
      "MW: Not yet implemented - new values of item should be stored."
    end

    get '/changestate/:id/setactive' do
      if session['auth']
        id = params[:id]
        Item.get_item(id).to_active
        redirect "/home/inactive"
      else
        redirect "/"
      end
    end

    get '/changestate/:id/setinactive' do
      if session['auth']
        id = params[:id]
        Item.get_item(id).to_inactive
        redirect "/home/active"
      else
        redirect "/"
      end
    end

    get '/buy/:id' do
      if session['auth']
        id = params[:id]
        item = Item.get_item(id)
        old_user = item.get_owner
        user = session['user']
        new_user = User.get_user(user)
        if new_user.buy_new_item?(item)
          old_user.remove_item(item)
        else
          redirect "/error/Not_Enough_Credits"
        end
        redirect "/home/active"
      else
        redirect "/"
      end
    end

  end
end