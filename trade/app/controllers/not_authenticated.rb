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
      haml :login, :locals => {:user_id => "0"}
    end

    get '/login/:id' do
      id = params[:id]
      redirect "/users/#{id}/1" unless session[:id].nil?
      haml :login, :locals => {:user_id => params[:id]}
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
      if session[:id]
        flash[:error] = "only one session allowed, please log out of all accounts"
        redirect "/home"
      else
        session["pwrecovery"] = params[:id]
        haml :pwreset
      end
    end

    post "/pwreset" do
      testuser = User.created("a", params[:password_new], "a@b.ch", "", "")
      if self.has_errors(testuser,params[:password_new], params[:password_check])
        redirect "/pwreset/#{session["pwrecovery"]}"
      else
        new_crypt = "barf"
        username = params[:username]
        #check if the user exists
        if !Trader.available?(username.strip.downcase)
          user = User.by_name username.strip.downcase
          new_crypt = BCrypt::Engine.hash_secret(session["pwrecovery"], user.password_salt)
        else
          user = nil
        end

        if PasswordReset.getValue(username.strip.downcase) == new_crypt #check for match between username and password-Link
          user.change_password(params[:password_new])
          flash[:notice] = "Your password is changed, please log in"
          redirect "/login"
        else
          flash[:error] = "wrong reset/user-combination"
          redirect "/home"
        end
      end
    end



    post "/authenticate/:id" do
      user = User.by_name params[:username].strip.downcase
      id = params[:id].to_i
      if !User.login user.id, params[:password] or user.nil?
        flash[:error] = "No such login"
        redirect "/login"
      else
        if id == 0
          session[:id] = user.id
          flash[:notice] = "Welcome, to the trading system. You are now logged in"
          redirect "/home"
        else
          session[:id] = user.id
          redirect "/users/#{id}/1"
        end
      end
    end

    get '/signup' do
      redirect '/home' unless session[:id].nil?
      haml :signup, :locals => {:name => "", :e_mail => "", :description => ""}
    end

    post '/signup' do
      redirect '/home' unless session[:id].nil?
      username, e_mail, description, pw, pw2 = params[:username].strip, params[:e_mail].strip, params[:description], params[:password1], params[:password2]
      filename = save_image(params[:image_file])

      user = User.created(username, pw, e_mail, description, filename)
      if self.has_errors(user,pw,pw2)
        haml :signup, :locals => {:name => username, :e_mail => e_mail, :description => description}
      else
        user.save
        flash[:notice] = "You are now registered. Please log in"
        redirect "/login"
      end
    end
    def has_errors(user,pw,pw1)
      is_valid_user = catch(:invalid){user.is_valid(pw,pw1,false)}
      case is_valid_user
        when true
          false
        when :invalid_name then
          flash[:error] = "User must have a name\n"
          true
        when :invalid_email then
          flash[:error] = "Invalid e-mail\n"
          true
        when :already_exists then
          flash[:error] = "Username already chosen\n"
          true
        when :no_pw_confirmation then
          flash[:error] = "Password confirmation is required\n"
          true
        when :no_pw then
          flash[:error] = "Password is required"
          true
        when :pw_dont_match then
          flash[:error] = "Passwords do not match\n"
          true
        when :pw_not_safe then
          flash[:error] = "Password is not safe\n"
          true
        when :big_image then
          flash[:error] = "Image is heavier than 400kB"
          true
        else
          flash[:error] = "The user is not valid."
          true
      end
    end
  end
end