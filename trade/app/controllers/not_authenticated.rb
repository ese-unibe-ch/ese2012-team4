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
require_relative('../models/utility/password_reset')
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

    get '/pwforgotten' do
      redirect '/home' unless session[:id].nil?
      haml :pwforgotten
    end

    post "/getnewpw" do
      user = User.by_name params[:username].strip.downcase

      if user.nil?
        flash[:error] = "No such login"
        redirect "/pwforgotten"
      else
        new_password = user.forgot_password
        Mailer.reset_pw(user.e_mail, "Hi #{user.name}, \n
        You forgot your password, you can reset your password with the following link: \n
        http://#{request.host}:#{request.port}/pwreset/#{new_password} \n")

        flash[:notice] = "Check your E-Mail for new login-information"
        redirect "/login"
      end
    end

    get '/pwreset/:id' do
      if !(PasswordReset.request_exists_for_id? params[:id])
        flash[:error] = "invalid link"
        redirect "/home"
      else
        session["pwrecovery"] = params[:id]
        username = PasswordReset.getKey(params[:id])
        user = User.by_name username
        haml :pwreset, :locals => {:user => user}
      end
    end

    post "/pwreset" do
      testuser = User.created("a", params[:password_new], "a@b.ch", "", "")
      unless testuser.is_valid(params[:password_new], params[:password_check])
        flash[:error] = testuser.errors
        redirect "/pwreset/#{session["pwrecovery"]}"
      else
        username = PasswordReset.getKey(session["pwrecovery"])
        user = User.by_name username.strip.downcase
        user.change_password(params[:password_new])
        flash[:notice] = "Your password is changed, please log in"
        redirect "/login"
      end
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