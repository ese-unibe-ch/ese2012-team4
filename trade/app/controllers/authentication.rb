def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'rubygems'
require 'require_relative'
require 'sinatra/base'
require 'haml'
require 'sinatra/content_for'
require_relative('../models/module/user')
require_relative('../models/module/password_check')

include Models

module Controllers
  class Authentication < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor

    post "/authenticate" do
      redirect "authenticate/login_fail", "No such login" unless User.login params[:username], params[:password]

      session[:username] = params[:username]
      #session['auth'] = true

      redirect "/home"
    end

    get "/authenticate/:error_msg" do
      case params[:error_msg]
        when "login_fail"
          haml :login, :locals => {:page_name => "Log in", :error => "no such login!"}
      end

    end

    post "/unauthenticate" do
      session[:username] = nil
      #session['auth'] = false
      redirect "/"
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

    post "/change_description" do
      viewer = User.get_user(session[:username])
      viewer.description(params[:description])
    end

    get "/profile/:error_msg" do
      if not session[:username].nil?
        case params[:error_msg]
          when "false_pw"
            haml :profile, :locals => {:page_name => "Your profile", :error => "You entered an incorrect password"}
          when "mismatch"
            haml :profile, :locals => {:page_name => "Your profile", :error => "The new password and the check do not match"}
          when "unsafe"
            haml :profile, :locals => {:page_name => "Your profile", :error => "Your password is unsafe"}
        end
      else
        redirect "/"
      end

    end
  end
end