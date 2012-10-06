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
        haml :home_new, :locals => {:action => "create", :name => "", :price => "", :description => "", :button => "Create"}
      else
        redirect "/"
      end
    end

    get '/home/edit_item' do
      # MW: To do: Get the right params.
      haml :home_new, :locals => {:action => "edit_item", :name => "something", :price => "some price", :description => "some text", :button => "Edit"}
    end

    get '/users' do
      if session['auth']
        viewer = session['user']
        haml :users, :locals => {:all_users => User.get_all(viewer)}
      else
        redirect "/"
      end
    end

    get '/users/:id' do
      if session['auth']
        user = params[:id]
        haml :users_id, :locals => {:active_items => User.get_user(user).list_items}
      else
        redirect "/"
      end
    end

    get '/items' do
      if session['auth']
        viewer = session['user']
        haml :items, :locals => {:all_items => Item.get_all(viewer)}
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
        haml :error, :locals => {:error_title => params[:title], :error_message => msg}
      else
        redirect "/"
      end
    end

  end
end