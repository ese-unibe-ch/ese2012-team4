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

    def authenticate!
      redirect "/index" unless session[:id]
    end

    get "/auction/:item_id/create" do
      authenticate!

      @item = Item.get_offer(params[:item_id])
      haml :create_auction
    end

    get '/auction/:item_id' do
      authenticate!

      redirect "/item/#{params[:item_id]}"
    end

    post '/auction/:id/create' do   #TODO: finish refactor here
      authenticate!

      id = params[:id]
      owner = Item.get_offer(id).owner
      viewer = User.get_user(session[:id])
      redirect '/index' unless owner == viewer.working_for
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
      if params[:currency]=="credits" or params[:currency]=="bitcoins"
        new_auction.currency = params[:currency]
      end
      if self.has_errors(new_auction)
        item_old.quantity += 1
        redirect back
      else
        Offer.remove_from_list(item_old)
        new_auction.owner.remove_offer(item_old)
        new_auction.owner.add_offer(new_auction)
        new_auction.save
        redirect "/home/items"
      end
    end

    post '/auction/:item_id/bid' do
      authenticate!

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
      authenticate!

      @item = Offer.get_offer(params[:item_id])
      haml :auction_edit
    end

    post "/auction/:item_id/edit" do
      authenticate!

      @auction = Offer.get_offer(params[:item_id])
      @item = @auction.item
      unless @auction.nil?
        owner = @auction.owner
        viewer = User.get_user(session[:id])
        redirect '/index' unless owner == viewer.working_for
        if owner == @session_user.working_for
          if @auction.editable?
            end_date = TimeHandler.parseTime(params[:exp_date], params[:exp_time])
            test_auction = Auction.create(@item, params[:increment], params[:min_price], end_date)
            if !self.has_errors(test_auction)
              @auction.min_price = params[:min_price].to_i
              @auction.expiration_date = end_date
              @auction.increment = params[:increment].to_i
              flash[:notice] = "Auction for item #{@item.name} has been edited!"
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
      authenticate!

      @auction = Offer.get_offer(params[:item_id])
      unless @auction.nil?
      owner = @auction.owner
      viewer = User.get_user(session[:id])
      redirect '/index' unless owner == viewer.working_for
        if (@session_user.working_for == @auction.owner)
          @auction.deactivate
        end
        redirect "/home/items"
      end
    end

    def has_errors(auction)
      validation = catch(:invalid){auction.is_valid?}
      case validation
        when :invalid_date then
          flash[:error] = "Select a valid End-Date for your auction.\n"
          true
        when :invalid_increment then
          flash[:error] = "Select a valid increment.\n"
          true
        when :invalid_min_price then
          flash[:error] = "Select a valid minimal price.\n"
          true
        when :invalid_currency then
          flash[:error] = "You need to set a Bitcoin wallet in your Profile to accept Bitcoins as payment"
          true
        else
          false
      end
    end
  end
end