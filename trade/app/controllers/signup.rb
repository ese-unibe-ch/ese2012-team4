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

      fail "enter a Username" if username == ''
      fail "enter a Password" if pw == ''

      fail "Passwords not identical" if pw != pw2
      password_check = Models::PasswordCheck.created
      fail "your password does not meet the standards" unless password_check.safe?(pw)
      fail "User name not available" unless User.available? username

      User.created(username, pw).save

      session['user'] = params[:username]
      session['auth'] = true

      redirect "/home"
    end

  end
end