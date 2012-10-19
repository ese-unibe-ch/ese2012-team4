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

    get '/users/:id' do
      redirect '/index' unless session[:id]
      @user = User.get_user(params[:id])
      haml :user_page, :locals => {:page_name => "User #{@user.name}"}
    end

    get "/user/:id/image" do
      redirect '/index' unless session[:id]
      path = User.get_user(params[:id]).image
      send_file(path)
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
        FileUtils::rm(filename)
        flash[:error] = test_user.errors
        redirect "/profile"
      else
        viewer.description = params[:description].split("\n")
        viewer.image = filename unless filename.include? "placeholder"
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

    get '/delete_link' do
      redirect '/index' unless session[:id]
      haml :delete_user, :locals =>{:page_name => "Delete Your Account"}
    end


    delete '/delete_account' do
      #delete user
      user = session[:id]
      FileUtils::rm(user.image)
      User.get_user(user).delete
      #close session
      session[:id] = nil
      redirect '/index' unless session[:id]
      haml :logout, :locals => {:page_name => "Logout"}
    end
  end
end