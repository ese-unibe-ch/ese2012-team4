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
  class Signup < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor

    post '/signup' do
      username, pw, pw2 = params[:username], params[:password1], params[:password2]

      redirect "/signup/no_user_name" if username==''
      redirect "/signup/taken" unless User.available? username
      redirect "/signup/no_pw" if pw == ''
      password_check = Models::PasswordCheck.created
      redirect "/signup/unsafe" unless password_check.safe?(pw)
      redirect "/signup/mismatch" if pw != pw2



      User.created(username, pw).save

      session[:username] = params[:username]
      #session['auth'] = true

      redirect "/home"
    end

    get "/signup/:error_msg" do
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
      end

    end

  end
end