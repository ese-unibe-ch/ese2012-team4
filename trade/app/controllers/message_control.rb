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
      
      from = 'tradingsystem.mail@gmail.com'
      to = recipient.e_mail
      pw = 'trade1234'
      site_url = request.host+":"+request.port.to_s

      content = <<EOF
From: #{sender.e_mail}
To: #{recipient.e_mail}
subject: [TradingSystem] #{subject}
Date: #{Time.now.rfc2822}
Content-Type: text/html
      
You have a new message from <a href="#{site_url}/login/#{@session_user.id}">#{@session_user.name}</a>:
<hr />
#{escape_html(content)}
<hr />
<br />
Regards,
The Trading System
EOF

      Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
      Net::SMTP.start('smtp.gmail.com', 587, 'gmail.com', from, pw, :login) do |smtp|
        smtp.send_message(content, from, to)
      end
			flash[:notice] = "Your message to #{recipient.name} has been sent"
      redirect '/users/'+recipient.id.to_s
    end
  end
end
