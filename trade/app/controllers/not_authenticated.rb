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
require_relative('../models/utility/password_check')
require_relative('helper')

include Models

module Controllers
  class Not_authenticated < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor
    use Rack::Flash

    get '/' do
      redirect "/home" if session[:id]
      redirect '/index'
    end

    get '/index' do
      redirect '/home' unless session[:id].nil?
      haml :index
    end

    get '/login' do
      redirect '/home' unless session[:id].nil?
      haml :login
    end

    post "/authenticate" do
      user = User.by_name params[:username].strip.downcase

      if !User.login user.id, params[:password] or user.nil?
        flash[:error] = "No such login"
        redirect "/login"
      else
        session[:id] = user.id
        flash[:notice] = "Welcome, #{user.name}. You are now logged in"
        redirect "/home"
      end
    end

    get '/signup' do
      redirect '/home' unless session[:id].nil?
      haml :signup
    end

    post '/signup' do
      redirect '/home' unless session[:id].nil?
      username, e_mail, description, pw, pw2 = params[:username].strip, params[:e_mail].strip, params[:description], params[:password1], params[:password2]
      filename = save_image(params[:image_file])

      user = User.created(username, pw, e_mail, description, filename)
      unless user.is_valid(pw, pw2)
        flash[:error] = user.errors
        redirect "/signup"
      else
        user.save
        flash[:notice] = "You are now registered. Please log in"
        redirect "/login"
      end
    end
  end
end