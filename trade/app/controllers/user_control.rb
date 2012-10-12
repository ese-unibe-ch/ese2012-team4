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
      @user = User.get_user(session[:username])
    end

    get '/logout' do
      redirect '/index' unless session[:username]
      haml :logout, :locals => {:page_name => "Logout", :error => nil}
    end

    get '/home' do
      redirect '/index' unless session[:username]
      haml :home, :locals => {:page_name => "Home", :error => nil}
    end

    get '/users' do
      redirect '/index' unless session[:username]
      haml :users, :locals => {:all_users => User.get_all(""), :page_name => "Users", :error => nil}
    end

    get '/users/:id' do
      redirect '/index' unless session[:username]
      user = params[:id]
      haml :users_id, :locals => {:active_items => User.get_user(user).list_items, :page_name => "User #{user}", :session_user => User.get_user(session[:username]), :user => User.get_user(user), :error => nil}
    end

    get '/users/:id/:error_msg' do
      redirect '/index' unless session[:username]
      user = params[:id]
      case params[:error_msg]
        when "not_enough_credits"
          haml :users_id, :locals => {:active_items => User.get_user(user).list_items, :session_user => User.get_user(session[:username]), :user => User.get_user(user), :page_name => "User #{user}", :error => "Not enough credits!"}
        when "out_of_sync"
          haml :users_id, :locals => {:active_items => User.get_user(user).list_items, :session_user => User.get_user(session[:username]), :user => User.get_user(user), :page_name => "User #{user}", :error => "Item has been edited while you tried to buy it!" }
      end
    end

    post "/unauthenticate" do
      redirect '/index' unless session[:username]
      session[:username] = nil
      #session['auth'] = false
      redirect "/"
    end

    get '/profile' do
      redirect '/index' unless session[:username]
      haml :profile, :locals => {:user => @user, :description => @user.description, :page_name => "Your profile", :error => nil}
    end

    get "/profile/:error_msg" do
      redirect '/index' unless session[:username]
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
      redirect '/index' unless session[:username]
      viewer = User.get_user(session[:username])
      to_insert = params[:description]
      list = to_insert.split("\n")
      viewer.description = list
      redirect "/profile"
    end

    post "/change_password" do
      redirect '/index' unless session[:username]
      password_check = PasswordCheck.created
      viewer = User.get_user(session[:username])
      redirect "/profile/false_pw" if !(viewer.check_password(params[:password_old]))
      redirect "/profile/mismatch" if params[:password_new]!=params[:password_check]
      redirect "/profile/unsafe"   if !password_check.safe?(params[:password_new])
      viewer.change_password(params[:password_new])
      redirect "/"
    end

    get '/delete_link' do
      redirect '/index' unless session[:username]
      haml :delete_user, :locals =>{:page_name => "Delete Your Account", :error => nil}
    end


    get '/delete_account' do
      #delete user
      user = session[:username]
      User.get_user(user).delete
      #close session
      session[:username] = nil
      redirect '/index' unless session[:username]
      haml :logout, :locals => {:page_name => "Logout", :error => nil}
    end
  end
end