def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'rubygems'
require 'require_relative'
require 'sinatra/base'
require 'haml'
require 'sinatra/content_for'
require 'rack-flash'
require_relative('../models/module/user')
require_relative('../models/module/item')
require_relative('helper')

include Models

module Controllers
  class UserControl < Sinatra::Base
    set :views, relative('../../app/views')
    set :public_folder, relative('../public')
    helpers Sinatra::ContentFor
    use Rack::Flash

    before do
      @session_user = User.get_user(session[:id])
    end

    get '/logout' do
      redirect '/index' unless session[:id]
      haml :logout, :locals => {:page_name => "Logout"}
    end

    get '/home' do
      redirect '/index' unless session[:id]
      haml :home, :locals => {:page_name => "Home"}
    end

    get '/users' do
      redirect '/index' unless session[:id]
      @all_users = User.get_all("")
      haml :users, :locals => {:page_name => "Users"}
    end

    get '/users/:id/:page' do
      redirect '/index' unless session[:id]
      @user = User.get_user(params[:id])
      items_per_page = 10
      page = params[:page].to_i
      items = @user.list_items
      (items.size%items_per_page)==0? page_count = (items.size/items_per_page).to_i : page_count = (items.size/items_per_page).to_i+1
      if(items.size==0)
        page_count=1;
      end
      redirect "users/#{params[:id]}/1" unless 0<params[:page].to_i and params[:page].to_i<page_count+1
      @all_items = []
      for i in ((page-1)*items_per_page)..(page*items_per_page)-1
        @all_items<<items[i] unless items[i].nil?
      end
      haml :user_page, :locals => {:page_name => "User #{@user.name}", :page => page, :page_count => page_count}
    end
    get '/users/:id' do
      redirect "/users/#{params[:id]}/1"
    end

    get "/user/:id/image" do
      redirect '/index' unless session[:id]
      path = User.get_user(params[:id]).image
      if path == ""
        send_file(File.join(FileUtils::pwd, "public/images/user_pix/placeholder_user.jpg"))
      else
        send_file(path)
      end
    end

    get "/rate/:id" do
      redirect '/index' unless session[:id]
      @user = User.get_user(params[:id])
      haml :rate_user
    end

    post "/rate/:id" do
      redirect '/index' unless session[:id]
      user = User.get_user(params[:id])
      user.add_rating(params[:rating]) unless params[:rating] == nil
      redirect "/home"
    end

    post "/unauthenticate" do
      redirect '/index' unless session[:id]
      session[:id] = nil
      #session['auth'] = false
      flash[:notice] = "You are now logged out"
      redirect "/"
    end

    get '/profile' do
      redirect '/index' unless session[:id]
      haml :profile, :locals => {:page_name => "My profile"}
    end

    post "/change_profile" do
      redirect '/index' unless session[:id]
      viewer = User.get_user(session[:id])
      filename = save_image(params[:image_file])
      test_user = User.created(viewer.name, "FdZ.(gJa)s'dFjKdaDGS+J1", params[:e_mail].strip, params[:description].split("\n"), filename)
      unless test_user.is_valid(nil, nil, false)
        flash[:error] = test_user.errors
        redirect "/profile"
      else
        viewer.description = params[:description].split("\n")
        if filename != ""
          FileUtils.rm(viewer.image, :force => true)
          viewer.image = filename
        end
        viewer.e_mail = params[:e_mail].strip
        flash[:notice] = "Profile has been updated"
        redirect "/profile"
      end
    end
    
    post "/change_password" do
      redirect '/index' unless session[:id]
      viewer = User.get_user(session[:id])
      unless viewer.is_valid(params[:password_new], params[:password_check], false)
        flash[:error] = viewer.errors
        redirect "/profile"
      end
      viewer.change_password(params[:password_new])
      flash[:notice] = "Password has been updated"
      redirect "/"
    end
    
    get '/profile/pending' do
      @inbox = @session_user.pending_inbox
      @outbox = @session_user.pending_outbox
      haml :pending_items
    end

    get '/delete_link' do
      redirect '/index' unless session[:id]
      haml :delete_user, :locals =>{:page_name => "Delete Your Account"}
    end


    delete '/delete_account' do
      #delete user
      user = session[:id]
      User.get_user(user).delete
      #close session
      session[:id] = nil
      redirect '/index' unless session[:id]
      haml :logout, :locals => {:page_name => "Logout"}
    end

    get '/wishlist' do
      redirect '/index' unless session[:id]
      haml :wishlist, :locals =>{:page_name => "Your Wishlist"}
    end

    post "/remove_from_wishlist/:itemid" do
      redirect '/index' unless session[:id]
      @item = Item.get_item(params[:itemid])
      @session_user.remove_from_wishlist(@item)
      redirect "#{back}"
    end

    post "/add_to_wishlist/:itemid" do
      redirect '/index' unless session[:id]
      @item = Item.get_item(params[:itemid])
      @session_user.add_to_wishlist(@item)
      redirect "#{back}"
    end

    post "/add_to_wishlist/:itemid" do
      redirect '/index' unless session[:id]
      id = params[:itemid]
      @item = Item.get_item(id)
      unless @item.active == true
        flash[:error] = "Item has been deactivated"
        redirect "/items"
      end
      @session_user.add_to_wishlist(@item)
      flash[:notice] = "Item has been added to your wishlist"
      redirect "/wishlist"
    end

  end
end