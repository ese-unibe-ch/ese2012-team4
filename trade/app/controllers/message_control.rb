def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'rubygems'
require 'require_relative'
require 'sinatra/base'
require 'haml'
require 'sinatra/content_for'
require 'rack-flash'
require 'tlsmail'
require_relative('../models/module/user')
include Rack::Utils

include Models

module Controllers
  class MessageControl < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor
    use Rack::Flash

    before do
      @session_user = User.get_user(session[:id])
    end

    get '/message/compose/:recipient_id' do
      redirect '/index' unless session[:id]
      @recipient = User.get_user(params[:recipient_id].to_i)
      haml :create_message
    end

    post '/message/send' do
      redirect '/index' unless session[:id]
      sender = @session_user
      recipient = User.get_user(params[:recipient_id].to_i)
      subject = params[:subject]
      content = params[:content]
      site_url = request.host+":"+request.port.to_s
      
      Mailer.send_personal_message(sender, recipient, subject, content, site_url)

      
			flash[:notice] = "Your message to #{recipient.name} has been sent"
      redirect '/users/'+recipient.id.to_s
    end
  end
end
