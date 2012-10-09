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
  class Authenticated < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor

    before do
      redirect '/index' unless session[:username]
      @user = User.get_user(session[:username])
    end


    
    get '/logout' do
      haml :logout, :locals => {:page_name => "Logout", :error => nil}
    end

    get '/home' do
      haml :home, :locals => {:page_name => "Home", :error => nil}
    end

    get '/home/active' do
        haml :home_active, :locals => {:active_items => @user.list_items, :page_name => "Active items", :error => nil}
    end

    get '/home/inactive' do
      haml :home_inactive, :locals => {:inactive_items => @user.list_items_inactive, :page_name => "Inactive items", :error => nil}
    end

    get '/home/new' do
      haml :home_new, :locals =>{:action => "create", :name => "", :price => "", :description =>"", :button => "Create", :page_name => "New Item", :error => nil}
    end

    get '/home/edit_item/:itemid' do

      if Item.get_item(params[:itemid]).is_owner?(@user.name)

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
      if Item.get_item(params[:itemid]).is_owner?(@user.name)
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
      haml :users, :locals => {:all_users => User.get_all(""), :page_name => "Users", :error => nil}
    end

    get '/users/:id' do
      user = params[:id]
      if user == @user.name
        redirect "/profile"
      else
        haml :users_id, :locals => {:active_items => User.get_user(user).list_items, :page_name => "User #{user}", :user => User.get_user(user), :error => nil}
      end
    end

    get '/users/:id/:error_msg' do
      user = params[:id]
      case params[:error_msg]
        when "not_enough_credits"
          haml :users_id, :locals => {:active_items => User.get_user(user).list_items, :user => User.get_user(user), :page_name => "User #{user}", :error => "Not enough credits!"}
      end
    end

    post "/unauthenticate" do
      session[:username] = nil
      #session['auth'] = false
      redirect "/"
    end

    get '/profile' do
      haml :profile, :locals => {:user => @user, :description => @user.description, :page_name => "Your profile", :error => nil}
    end

    get "/profile/:error_msg" do
      if not session[:username].nil?
        case params[:error_msg]
          when "false_pw"
            haml :profile, :locals => {:page_name => "Your profile", :user => User.get_user(session[:username]), :error => "You entered an incorrect password"}
          when "mismatch"
            haml :profile, :locals => {:page_name => "Your profile", :user => User.get_user(session[:username]), :error => "The new password and the check do not match"}
          when "unsafe"
            haml :profile, :locals => {:page_name => "Your profile", :user => User.get_user(session[:username]), :error => "Your password is unsafe"}
        end
      else
        redirect "/"
      end

    end

    post "/change_description" do
      viewer = User.get_user(session[:username])
      to_insert = params[:description]
      list = to_insert.split("\n")
      viewer.description = list
      redirect "/profile"
    end

    post "/change_password" do
      password_check = PasswordCheck.created
      viewer = User.get_user(session[:username])
      redirect "/profile/false_pw" if !(viewer.check_password(params[:password_old]))
      redirect "/profile/mismatch" if params[:password_new]!=params[:password_check]
      redirect "/profile/unsafe"   if !password_check.safe?(params[:password_new])
      viewer.change_password(params[:password_new])
      redirect "/"
    end



    get '/items' do
      haml :items, :locals => {:all_items => Item.get_all(@user.name), :page_name => "Items", :error => nil }
    end

    get '/items/:error_msg' do
      case params[:error_msg]
        when "not_enough_credits"
          haml :items, :locals => {:all_items => Item.get_all(@user.name), :page_name => "Items", :error => "Not enough credits!" }
      end
    end

    post '/create' do
      user = session[:username]
      price = params[:price]

      unless Item.valid_price?(price)
        redirect "create/not_a_number"
      end
      #error handling for empty names or whitespaces (strip removes all kind of whitespaces, but not the first space)
      unless params[:name].strip.delete(' ')!=""
        redirect '/create/no_name'
      end
      User.get_user(user).create_item(params[:name], Integer(params[:price]), params[:description])
      # MW: maybe "User.by_name" might be somewhat more understandable
      redirect "/home/inactive"
    end

    get '/create/:error_msg' do
      case params[:error_msg]
        when "not_a_number"
          haml :home_new, :locals =>{:action => "create", :name => "", :price => "", :description =>"", :button => "Create", :page_name => "New Item", :error => "Your price is not a valid number!"}
        when "no_name"
          haml :home_new, :locals =>{:action => "create", :name => "", :price => "", :description =>"", :button => "Create", :page_name => "New Item", :error => "You have to choose a name for your item!"}
      end
    end

    post '/edit_item/:itemid' do
      #error handling for empty names or whitespaces (strip removes all kind of whitespaces, but not the first space)
      unless params[:name].strip.delete(' ')!=""
        redirect "/home/edit_item/#{params[:itemid]}/no_name"
      end
      item = Item.get_item(params[:itemid])
      price = params[:price]
      unless Item.valid_price?(String(price))
        redirect "/home/edit_item/#{params[:itemid]}/not_a_number"

      end
      item.name = params[:name]
      item.price = params[:price].to_i
      item.description = params[:description]
      redirect "/home/inactive"
    end

    get '/changestate/:id/setactive' do
      id = params[:id]
      Item.get_item(id).active = true
      redirect "/home/inactive"
    end

    post '/changestate/:id/setinactive' do
      id = params[:id]
      Item.get_item(id).active = false
      redirect "/home/active"
    end

    post '/buy/:id' do               # TODO: change to post!
      id = params[:id]
      item = Item.get_item(id)
      old_user = item.owner
      user = session[:username]
      new_user = User.get_user(user)
      if new_user.buy_new_item?(item)
        old_user.remove_item(item)
      else
        if back.include? '/not_enough_credits'
          redirect "#{back}"
        else
          redirect "#{back}/not_enough_credits"
        end
      end
      redirect "/home/inactive"
    end

  end
end