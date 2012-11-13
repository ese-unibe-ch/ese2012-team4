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
require_relative('../models/module/item')

include Models

module Controllers
  class AuctionControl < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor
    use Rack::Flash

    before do
      @session_user = User.get_user(session[:id])
    end

    get "/auction/:item_id/create" do
      redirect "/index" unless session[:id]
      @item = Item.get_item(params[:item_id])
      haml :create_auction
    end

    post '/auction/:id/create' do
      redirect '/index' unless session[:id]
      id = params[:id]
      owner = Item.get_item(id).owner
      item = Item.get_item(id)
      if(TimeHandler.validTime?(params[:exp_date], params[:exp_time]))
        if ((params[:exp_date].eql?("") and params[:exp_time].eql?("")))
          flash[:error] = "You must enter an end date"
        else
          expiration_date= TimeHandler.parseTime(params[:exp_date], params[:exp_time])
          owner.add_auction(item,params[:min_price],params[:increment],expiration_date)
          flash[:notice] = "Auction for item #{item.name} has been created!"
        end
      else
        flash[:error] = "You did not put in a valid Time"
      end
      redirect "/home/items"
    end

  end
end