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
  class Sites < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor

    get '/' do
      if not session[:username].nil?
        redirect "/home"
      else
        haml :index, :locals => {:page_name => "Home", :error => nil}
      end
    end

    get '/login' do
      if not session[:username].nil?
        redirect "/home"
      else
        haml :login, :locals => {:page_name => "Log in", :error => nil}
      end
    end
    
    get '/signup' do
      haml :signup, :locals => {:page_name => "Sign up", :error => nil}
    end

    get '/logout' do
      if not session[:username].nil?
        haml :logout, :locals => {:page_name => "Logout", :error => nil}
      else
        redirect "/"
      end
    end

    get '/home' do
      if not session[:username].nil?
        haml :home, :locals => {:page_name => "Home", :error => nil}
      else
        redirect "/"
      end
    end

    get '/home/active' do
      if not session[:username].nil?
        user = session[:username]
        haml :home_active, :locals => {:active_items => User.get_user(user).list_items, :page_name => "Active items", :error => nil}
      else
        redirect "/"
      end
    end

    get '/home/inactive' do
      if not session[:username].nil?
        user = session[:username]
        haml :home_inactive, :locals => {:inactive_items => User.get_user(user).list_items_inactive, :page_name => "Inactive items", :error => nil}
      else
        redirect "/"
      end
    end

    get '/home/new' do
      if not session[:username].nil?
        haml :home_new, :locals =>{:action => "create", :name => "", :price => "", :description =>"", :button => "Create", :page_name => "New Item", :error => nil}
      else
        redirect "/"
      end
    end

    get '/home/edit_item/:itemid' do

      if (not session[:username].nil?) && Item.get_item(params[:itemid]).is_owner?(session[:username])

        item = Item.get_item(params[:itemid])
        item_name = item.name
        price = item.price
        description = item.description
        unless Item.valid_price?(String(price))
          redirect "/home/edit_item/#{params[:itemid]}/not_a_number"
        end

        # MW: To do: Get the right params.
        haml :home_new, :locals => {:action => "edit_item/#{params[:itemid]}", :name => item_name, :price => price, :description => description, :button => "Edit", :page_name => "Edit Item", :error => nil}
      else
        redirect "/"
      end
    end

    get '/home/edit_item/:itemid/:error_msg' do
      if (not session[:username].nil?) && Item.get_item(params[:itemid]).is_owner?(session[:username])
        item = Item.get_item(params[:itemid])
        item_name = item.name
        price = item.price
        description = item.description

        case params[:error_msg]
          when "not_a_number"
            haml :home_new, :locals => {:action => "edit_item/#{params[:itemid]}", :name => item_name, :price => price, :description => description, :button => "Edit", :page_name => "Edit Item", :error => "Your price is not a valid number!"}
          when "no_name"
            haml :home_new, :locals => {:action => "edit_item/#{params[:itemid]}", :name => item_name, :price => price, :description => description, :button => "Edit", :page_name => "Edit Item", :error => "You have to choose a name for your item!"}
        end
      else
        redirect "/"
      end
    end

    get '/users' do
      if not session[:username].nil?
        viewer = session[:username]
        haml :users, :locals => {:all_users => User.get_all(""), :page_name => "Users", :error => nil}
      else
        redirect "/"
      end
    end

    get '/users/:id' do
      if not session[:username].nil?
        user = params[:id]
        viewer = session[:username]
        if user == viewer
          redirect "/profile"
        else
          haml :users_id, :locals => {:active_items => User.get_user(user).list_items, :page_name => "User #{user}", :user => User.get_user(user), :error => nil}
        end
      else
        redirect "/"
      end
    end

    get '/users/:id/:error_msg' do
      if not session[:username].nil?
        user = params[:id]
        case params[:error_msg]
          when "not_enough_credits"
            haml :users_id, :locals => {:active_items => User.get_user(user).list_items, :page_name => "User #{user}", :error => "Not enough credits!"}
        end
      else
        redirect "/"
      end
    end


    get '/profile' do
      if not session[:username].nil?
        user = session[:username]
        haml :profile, :locals => {:user => User.get_user(user), :description => User.get_user(user).description, :page_name => "Your profile", :error => nil}
      else
        redirect "/"
      end
    end

    get '/items' do
      if not session[:username].nil?
        viewer = session[:username]
        haml :items, :locals => {:all_items => Item.get_all(viewer), :page_name => "Items", :error => nil }
      else
        redirect "/"
      end
    end

    get '/items/:error_msg' do
      if not session[:username].nil?
        viewer = session[:username]
        case params[:error_msg]
          when "not_enough_credits"
            haml :items, :locals => {:all_items => Item.get_all(viewer), :page_name => "Items", :error => "Not enough credits!" }
        end

      else
        redirect "/"
      end
    end
  end
end