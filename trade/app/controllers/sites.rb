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
        user = session['user']
        haml :home_active, :locals => {:active_items => User.get_user(user).list_items, :page_name => "Active items", :error => nil}
      else
        redirect "/"
      end
    end

    get '/home/inactive' do
      if not session[:username].nil?
        user = session['user']
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
      if not session[:username].nil?
        item = Item.get_item(params[:itemid])
        item_name = item.name
        price = item.price
        description = item.description

        # MW: To do: Get the right params.
        haml :home_new, :locals => {:action => "edit_item/#{params[:itemid]}", :name => item_name, :price => price, :description => description, :button => "Edit", :page_name => "Edit Item", :error => nil}
      else
        redirect "/"
      end
    end

    get '/users' do
      if not session[:username].nil?
        viewer = session['user']
        haml :users, :locals => {:all_users => User.get_all(viewer), :page_name => "Users", :error => nil}
      else
        redirect "/"
      end
    end

    get '/users/:id' do
      if not session[:username].nil?
        user = params[:id]
        viewer = session['user']
        if user == viewer
          redirect "/profile"
        else
          haml :users_id, :locals => {:active_items => User.get_user(user).list_items, :page_name => "User #{user}", :error => nil}
        end
      else
        redirect "/"
      end
    end

    get "/profile" do
      if not session[:username].nil?
        haml :profile, :locals => {:page_name => "Your profile", :error => nil}
      end
    end

    get '/items' do
      if not session[:username].nil?
        viewer = session['user']
        haml :items, :locals => {:all_items => Item.get_all(viewer), :page_name => "Items", :error => nil }
      else
        redirect "/"
      end
    end
    get '/items/:error_msg' do
      if not session[:username].nil?
        viewer = session['user']
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