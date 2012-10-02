def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'rubygems'
require 'require_relative'
require 'sinatra/base'
require 'haml'
require 'sinatra/content_for'
require_relative('../models/module/user')

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

  end
end