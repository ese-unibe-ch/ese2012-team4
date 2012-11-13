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
require_relative('../models/module/auction')

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

    get '/auction/:item_id' do
      @item = Item.get_item(params[:item_id])
      @auction = Auction.auction_by_item(@item)
      haml :auction_page
    end

    post '/auction/:id/create' do
      redirect '/index' unless session[:id]
      id = params[:id]
      owner = Item.get_item(id).owner
      item = Item.get_item(id)
      #TODO deny item with more than one element...
      if(TimeHandler.validTime?(params[:exp_date], params[:exp_time]))
        if ((params[:exp_date].eql?("") and params[:exp_time].eql?("")))
          flash[:error] = "You must enter an end date"
        else
          if params[:increment].to_i > 0
            if params[:min_price].to_i > 0
              if Auction.auction_by_item(item)
                flash[:error] = "Auction with this item already exists."
              else
                end_date = TimeHandler.parseTime(params[:exp_date], params[:exp_time])
                Auction.create(owner, item, params[:increment], params[:min_price], end_date)
                flash[:notice] = "Auction for item #{item.name} has been created!"
              end
            else
              flash[:error] = "Please specify a valid minimal price (greater than 0)"
            end
          else
            flash[:error] = "Please specify a valid increment (greater than 0)"
          end

        end
      else
        flash[:error] = "You did not put in a valid Time"
      end
      redirect "/home/items"
    end

    post '/auction/:item_id/bid' do
       puts "placed a bid of " + params[:bid]
       redirect "/auction/#{params[:item_id]}"
    end

  end
end