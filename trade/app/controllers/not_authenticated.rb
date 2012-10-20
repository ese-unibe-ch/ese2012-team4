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
      haml :index, :locals => {:page_name => "Home"}
    end

    get '/login' do
      redirect '/home' unless session[:id].nil?
      haml :login, :locals => {:page_name => "Log in"}
    end

    post "/authenticate" do
      user = User.by_name params[:username].strip.downcase
      unless User.login user.id, params[:password]
        flash[:error] = "No such login"
        redirect "/login"
      else
        session[:id] = user.id
        #session['auth'] = true
        flash[:notice] = "You are now logged in"
        redirect "/home"
      end
    end

    get '/signup' do
      redirect '/home' unless session[:id].nil?
      haml :signup, :locals => {:page_name => "Sign up"}
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
      
      #redirect "/signup/invalid_username" if username != username.delete("^a-zA-Z0-9")  
      #BS: only needed if we don't allow special characters
    end
  end
end