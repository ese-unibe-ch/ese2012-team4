def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'rubygems'
require 'require_relative'
require 'sinatra/base'
require 'haml'
require 'sinatra/content_for'
require_relative('../models/module/user')
require_relative('../models/utility/password_check')

include Models

module Controllers
  class Not_authenticated < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor

    get '/' do
      redirect "/home" if session[:id]
      redirect '/index'
    end

    get '/index' do
      redirect '/home' unless session[:id].nil?
      haml :index, :locals => {:page_name => "Home", :error => nil}
    end

    get '/login' do
      redirect '/home' unless session[:id].nil?
      haml :login, :locals => {:page_name => "Log in", :error => nil}
    end

    post "/authenticate" do
      user = User.by_name params[:username].strip.downcase
      redirect "authenticate/login_fail", "No such login" unless User.login user.id, params[:password]

      session[:id] = user.id
      #session['auth'] = true

      redirect "/home"
    end

    get "/authenticate/:error_msg" do
      redirect '/home' unless session[:id].nil?
      case params[:error_msg]
        when "login_fail"
          haml :login, :locals => {:page_name => "Log in", :error => "no such login!"}
      end

    end

    get '/signup' do
      redirect '/home' unless session[:id].nil?
      haml :signup, :locals => {:page_name => "Sign up", :error => nil}
    end

    post '/signup' do
      redirect '/home' unless session[:id].nil?
      username,description, pw, pw2 = params[:username].strip, params[:description], params[:password1], params[:password2]

      #redirect "/signup/invalid_username" if username != username.delete("^a-zA-Z0-9")  
      #BS: only needed if we don't allow special characters 

      redirect "/signup/no_user_name" if username==''
      redirect "/signup/taken" unless User.available? username
      redirect "/signup/no_pw" if pw == ''
      password_check = Models::PasswordCheck.created
      redirect "/signup/unsafe" unless password_check.safe?(pw)
      redirect "/signup/mismatch" if pw != pw2
      User.created(username, pw, description).save
      redirect "/login"
    end

    get "/signup/:error_msg" do
      redirect '/home' unless session[:id].nil?
      case params[:error_msg]
        when "no_user_name"
          haml :signup, :locals=> {:page_name => "Sign up", :error => "Enter an username!"}
        when "no_pw"
          haml :signup, :locals=> {:page_name => "Sign up", :error => "Enter a password!"}
        when "mismatch"
          haml :signup, :locals=> {:page_name => "Sign up", :error => "Passwords do not match!"}
        when "unsafe"
          haml :signup, :locals=> {:page_name => "Sign up", :error => "Your password is unsafe!"}
        when "taken"
          haml :signup, :locals=> {:page_name => "Sign up", :error => "This username is already taken!"}
        #when "invalid_username"
        #  haml :signup, :locals=> {:page_name => "Sign up", :error => "Invalid username!"}
        #BS: only needed if we don't allow special characters 
      end

    end

  end
end