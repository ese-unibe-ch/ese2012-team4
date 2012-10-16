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
  class UserControl < Sinatra::Base
    set :views, relative('../../app/views')
    set :public_folder, relative('../public')
    helpers Sinatra::ContentFor

    before do
      @session_user = User.get_user(session[:id])
    end

    get '/logout' do
      redirect '/index' unless session[:id]
      haml :logout, :locals => {:page_name => "Logout", :error => nil}
    end

    get '/home' do
      redirect '/index' unless session[:id]
      haml :home, :locals => {:page_name => "Home", :error => nil}
    end

    get '/users' do
      redirect '/index' unless session[:id]
      @all_users = User.get_all("")
      haml :users, :locals => {:page_name => "Users", :error => nil}
    end

    get '/users/:id' do
      redirect '/index' unless session[:id]
      @user = User.get_user(params[:id])
      haml :user_page, :locals => {:page_name => "User #{@user.name}", :error => nil}
    end

    get '/users/:id/:error_msg' do
      redirect '/index' unless session[:id]
      @user = User.get_user(params[:id])
      case params[:error_msg]
        when "not_enough_credits"
          haml :user_page, :locals => {:page_name => "User #{@user.name}", :error => "Not enough credits!"}
        when "out_of_sync"
          haml :user_page, :locals => {:page_name => "User #{@user.name}", :error => "Item has been edited while you tried to buy it!" }
      end
    end

    post "/unauthenticate" do
      redirect '/index' unless session[:id]
      session[:id] = nil
      #session['auth'] = false
      redirect "/"
    end

    get '/profile' do
      redirect '/index' unless session[:id]
      haml :profile, :locals => {:page_name => "My profile", :error => nil}
    end

    get "/profile/:error_msg" do
      redirect '/index' unless session[:id]
      if not session[:id].nil?
        @user = User.get_user(session[:id])
        case params[:error_msg]
          when "false_pw"
            haml :profile, :locals => {:page_name => "My profile", :error => "You entered an incorrect password"}
          when "mismatch"
            haml :profile, :locals => {:page_name => "My profile", :error => "The new password and the check do not match"}
          when "unsafe"
            haml :profile, :locals => {:page_name => "My profile", :error => "Your password is unsafe"}
        end
      else
        redirect "/"
      end

    end

    post "/change_description" do
      redirect '/index' unless session[:id]
      viewer = User.get_user(session[:id])
      to_insert = params[:description]
      list = to_insert.split("\n")
      viewer.description = list
      redirect "/profile"
    end

    post "/change_password" do
      redirect '/index' unless session[:id]
      password_check = PasswordCheck.created
      viewer = User.get_user(session[:id])
      redirect "/profile/false_pw" if !(viewer.check_password(params[:password_old]))
      redirect "/profile/mismatch" if params[:password_new]!=params[:password_check]
      redirect "/profile/unsafe"   if !password_check.safe?(params[:password_new])
      viewer.change_password(params[:password_new])
      redirect "/"
    end

    get '/delete_link' do
      redirect '/index' unless session[:id]
      haml :delete_user, :locals =>{:page_name => "Delete Your Account", :error => nil}
    end


    delete '/delete_account' do
      #delete user
      user = session[:id]
      User.get_user(user).delete
      #close session
      session[:id] = nil
      redirect '/index' unless session[:id]
      haml :logout, :locals => {:page_name => "Logout", :error => nil}
    end
  end
end