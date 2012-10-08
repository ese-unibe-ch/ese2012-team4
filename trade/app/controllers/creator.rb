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
      if not session[:username].nil?
        user = session[:username]
        begin
          User.get_user(user).create_item(params[:name], Integer(params[:price]), params[:description])
          # MW: maybe "User.by_name" might be somewhat more understandable
        rescue
          get '/create/not_a_number'
        end
        redirect "/home/inactive"
      else
        redirect "/"
      end
    end

    get '/create/:error_msg' do
      case params[:error_msg]
        when "not_a_number"
          haml :home_new, :locals =>{:action => "create", :name => "", :price => "", :description =>"", :button => "Create", :page_name => "New Item", :error => "Your price is not a number!"}
      end
    end

    post '/edit_item/:itemid' do
      item = Item.get_item(params[:itemid])
      item.delete # MW: should not be necessary => Refactor-Issue (the list @@items should be reorganized...)
      item.name = params[:name]
      item.price = params[:price].to_i
      item.description = params[:description]
      item.save # MW: should not be necessary, since the item is already in the system and only its properties have changed!
      redirect "/home/inactive"
    end

    get '/changestate/:id/setactive' do
      if not session[:username].nil?
        id = params[:id]
        Item.get_item(id).active = true
        redirect "/home/inactive"
      else
        redirect "/"
      end
    end

    get '/changestate/:id/setinactive' do
      if not session[:username].nil?
        id = params[:id]
        Item.get_item(id).active = false
        redirect "/home/active"
      else
        redirect "/"
      end
    end

    get '/buy/:id' do
      if not session[:username].nil?
        id = params[:id]
        item = Item.get_item(id)
        old_user = item.owner
        user = session['user']
        new_user = User.get_user(user)
        if new_user.buy_new_item?(item)
          old_user.remove_item(item)
        else
          redirect "/items/not_enough_credits"
        end
        redirect "/home/inactive"
      else
        redirect "/"
      end
    end

  end
end