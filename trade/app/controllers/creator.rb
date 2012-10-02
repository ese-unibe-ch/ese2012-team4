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
  class Creator < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor

    post '/create' do
      if session['auth']
        user = session['user']
        User.get_user(user).create_item(params[:name], params[:price])
        redirect "/home/inactive"
      else
        redirect "/home"
      end
    end

  end
end