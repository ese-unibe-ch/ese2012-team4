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
      halt 401, "No such login" unless User.login params[:username], params[:password]

      session['user'] = params[:username]
      session['auth'] = true

      redirect "/home"
    end

    post "/unauthenticate" do
      session['user'] = nil
      session['auth'] = false
      redirect "/"
    end

    post "/change_password" do
      password_check = PasswordCheck.created
      if User.login session['user'], params[:password_old] == false
        halt 401, "false password"
      end
      if params[:password_new]!=params[:password_check]
        halt 401, "new password and check do not match"
      end
      if !password_check.safe?(params[:password_new])
        halt 401, "password unsafe, choose another one"
      end
      redirect "/"

    end

  end
end