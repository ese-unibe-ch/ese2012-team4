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
      if session['auth']
        redirect "/home"
      else
        haml :index, :locals => {:page_name => "Home"}
      end
    end

    get '/login' do
      if session['auth']
        redirect "/home"
      else
        haml :login, :locals => {:page_name => "Log in"}
      end
    end

    get '/signup' do
      haml :signup, :locals => {:page_name => "Sign up"}
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
        haml :home, :locals => {:page_name => "Home"}
      else
        redirect "/"
      end
    end

    get '/home/active' do
      if session['auth']
        user = session['user']
        haml :home_active, :locals => {:active_items => User.get_user(user).list_items, :page_name => "Active items"}
      else
        redirect "/"
      end
    end

    get '/home/inactive' do
      if session['auth']
        user = session['user']
        haml :home_inactive, :locals => {:inactive_items => User.get_user(user).list_items_inactive, :page_name => "Inactive items"}
      else
        redirect "/"
      end
    end

    get '/home/new' do
      if session['auth']
        haml :home_new, :locals =>{:page_name => "Home"}
      else
        redirect "/"
      end
    end

    get '/users' do
      if session['auth']
        viewer = session['user']
        haml :users, :locals => {:all_users => User.get_all(viewer), :page_name => "Users"}
      else
        redirect "/"
      end
    end

    get '/users/:id' do
      if session['auth']
        user = params[:id]
        viewer = session['user']
        if user == viewer
          haml :profile, :locals => {:page_name => "Your profile"}
        else
          haml :users_id, :locals => {:active_items => User.get_user(user).list_items, :page_name => "User #{user.name}"}
        end
      else
        redirect "/"
      end
    end

    get '/items' do
      if session['auth']
        viewer = session['user']
        haml :items, :locals => {:all_items => Item.get_all(viewer), :page_name => "Items"}
      else
        redirect "/"
      end
    end

    get '/error/:title' do
      if session['auth']
        msg = ""
        if params[:title] == "Not_A_Number"
          msg = "Price should be a number!"
        end
        if params[:title] == "Not_Enough_Credits"
          msg = "Sorry, but you can't buy this item, because you have not enough credits!"
        end
        haml :error, :locals => {:error_title => params[:title], :error_message => msg , :page_name => "Error"}
      else
        redirect "/"
      end
    end


  end
end