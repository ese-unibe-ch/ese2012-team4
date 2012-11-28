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
require_relative('../models/module/activity')

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
      @item = Item.get_offer(params[:item_id])
      haml :create_auction
    end

    get '/auction/:item_id' do
      redirect "/item/#{params[:item_id]}"
    end

    post '/auction/:id/create' do   #TODO: finish refactor here
      redirect '/index' unless session[:id]
      id = params[:id]
      owner = Item.get_offer(id).owner
      item_old = Item.get_offer(id)
      #if item_old.quantity != 1
      #  item_old.quantity -= 1
      #  item_new = item_old.copy(:quantity => 1)
      #  item_new.save
      #else
        item_new = item_old
      #end
      end_date = TimeHandler.parseTime(params[:exp_date], params[:exp_time])
      new_auction = Auction.create(item_new, params[:increment], params[:min_price], end_date)
      if new_auction.is_valid?
        Offer.remove_from_list(item_old)
        new_auction.owner.remove_offer(item_old)
        new_auction.owner.add_offer(new_auction)
        new_auction.save
      else
        flash[:error] = new_auction.errors
        item_old.quantity += 1
      end
      redirect "/home/items"
    end

    post '/auction/:item_id/bid' do
      @auction = Offer.get_offer(params[:item_id])
      redirect '/index' unless @auction.auction
      unless @auction.nil?

        if (@session_user.working_for == @auction.owner)
          flash[:error] = "Can't bid on yur own item!'"
        else
          success = @auction.place_bid(@session_user.working_for, params[:bid].to_i)
          if success == :not_enough_credits
            flash[:error] = "you don't have enough credits!'"
          end
          if  success == :invalid_bid
            flash[:error] = "this bid is invalid!"
          end
          if success == :bid_already_made
            flash[:error] = "this bid already exists'"
          end

          if success == :success
            flash[:notice] = "Bid of #{params[:bid]} placed for item #{@auction.name}!"
            Activity.log(@session_user, "bid", @auction, @session_user.working_for)
          end
        end
        redirect "/auction/#{params[:item_id]}"
      else
        redirect "/index"
      end
    end

    get "/auction/:item_id/edit" do
      redirect "/" unless session[:id]
      @item = Offer.get_offer(params[:item_id])
      haml :auction_edit
    end

    post "/auction/:item_id/edit" do
      redirect '/index' unless session[:id]
      @auction = Offer.get_offer(params[:item_id])
      @item = @auction.item
      unless @auction.nil?
        if @auction.owner == @session_user.working_for
          if @auction.editable?
            end_date = TimeHandler.parseTime(params[:exp_date], params[:exp_time])
            test_auction = Auction.create(@item, params[:increment], params[:min_price], end_date)
            if test_auction.is_valid?
              @auction.min_price = params[:min_price].to_i
              @auction.expiration_date = end_date
              @auction.increment = params[:increment].to_i
              flash[:notice] = "Auction for item #{@item.name} has been edited!"
            else
              flash[:error] = test_auction.errors
            end
          else
            flash[:error] = "Item cannot be edited."
          end
        end
      else
        flash[:error] = "Auction does not exist."
      end
      redirect "/home/items"
    end

    post "/auction/:item_id/deactivate" do
      redirect '/index' unless session[:id]
      @auction = Offer.get_offer(params[:item_id])
      if (@session_user.working_for == @auction.owner)
        @auction.deactivate
      end
      redirect "/home/items"
    end

  end
end