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
require_relative('../models/utility/holding')
require_relative('../models/utility/time_handler')
require_relative('helper')

include Models

module Controllers
  class ItemControl < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor
    use Rack::Flash
    @@item_map = Hash.new()

    before do
      @session_user = User.get_user(session[:id])
    end

    get '/search' do
      redirect '/index' unless session[:id]
      haml :search
    end

    post '/search/query' do
      redirect '/index' unless session[:id]
      input = params[:search]
      @@item_map[session[:id]]= Item.search(input,User.get_user(session[:id]))
      redirect '/search/result/1'
    end

    get '/search/result/:page' do
      redirect '/index' unless session[:id]
      redirect '/search' if @@item_map[session[:id]].nil?
      items_per_page = 10
      page = params[:page].to_i
      items = @@item_map[session[:id]]
      (items.size%items_per_page)==0? page_count = (items.size/items_per_page).to_i : page_count = (items.size/items_per_page).to_i+1
      if page_count ==0
        page_count=1
      end
      redirect 'search/result/1' unless 0<params[:page].to_i and params[:page].to_i<page_count+1

      @items = []
      for i in ((page-1)*items_per_page)..(page*items_per_page)-1
        @items<<items[i] unless items[i].nil?
      end
      haml :items, :locals=> {:title => 'Search Result', :page => page, :page_count =>page_count}
    end

    get '/search/result' do
      redirect '/index' unless session[:id]
      redirect '/search/result/1'
    end

    get '/home/items/:active/:inactive' do
      redirect '/index' unless session[:id]
      items_per_page = 10
      active = params[:active].to_i
      inactive = params[:inactive].to_i
      active_items = @session_user.working_for.list_items
      (active_items.size%items_per_page)==0? active_page_count = (active_items.size/items_per_page).to_i : active_page_count = (active_items.size/items_per_page).to_i+1
      if active_items.size==0
        active_page_count=1
      end
      redirect 'home/items/1/1' unless 0<params[:active].to_i and params[:active].to_i<active_page_count+1
      inactive_items = @session_user.working_for.list_items_inactive
      (inactive_items.size%items_per_page)==0? inactive_page_count = (inactive_items.size/items_per_page).to_i : inactive_page_count = (inactive_items.size/items_per_page).to_i+1
      if inactive_items.size==0
        inactive_page_count=1
      end
      redirect 'home/items/1/1' unless 0<params[:inactive].to_i and params[:inactive].to_i<inactive_page_count+1

      @active_items = []
      for i in ((active-1)*items_per_page)..(active*items_per_page)-1
        @active_items<<active_items[i] unless active_items[i].nil?
      end
      @inactive_items = []
      for i in ((inactive-1)*items_per_page)..(inactive*items_per_page)-1
        @inactive_items<<inactive_items[i] unless inactive_items[i].nil?
      end
      @auctions = Auction.auctions_by_user(@session_user.working_for)
      haml :user_items, :locals => {:active_page =>active, :active_page_count =>active_page_count, :inactive_page =>inactive, :inactive_page_count => inactive_page_count}
    end

    get '/home/items' do
      redirect '/index' unless session[:id]
      redirect '/home/items/1/1'
    end

    get '/home/new' do
      redirect '/index' unless session[:id]
      @item = Item.created("", "", "", "", "");
      haml :item_edit, :locals =>{:action => "create", :button => "Create"}
    end

    get '/home/edit_item/:itemid' do
      redirect '/index' unless session[:id]
      if Item.get_item(params[:itemid]).is_owner?(@session_user.working_for.id)
        @item = Item.get_item(params[:itemid])
        haml :item_edit, :locals => {:action => "change/#{params[:itemid]}", :button => "Save changes"}
      else
        redirect "/"
      end
    end

    get '/items/:page' do
      redirect '/index' unless session[:id]

      items_per_page = 10
      page = params[:page].to_i
      items = Item.get_all(@session_user.working_for.name)
      (items.size%items_per_page)==0? page_count = (items.size/items_per_page).to_i : page_count = (items.size/items_per_page).to_i+1
      redirect 'items/1' unless 0<params[:page].to_i and params[:page].to_i<page_count+1
      @items = []
      for i in ((page-1)*items_per_page)..(page*items_per_page)-1
        @items<<items[i] unless items[i].nil?
      end
      haml :items, :locals => {:title => 'All Items', :page => page, :page_count => page_count}
    end

    get '/items' do
      redirect '/index' unless session[:id]
      redirect '/items/1'
    end

    get '/item/:itemid' do
      redirect '/index' unless session[:id]
      id = params[:itemid]
      @item = Item.get_item(id)
      haml :item_page
    end

    post '/create' do
      redirect '/index' unless session[:id]
      name = params[:name]
      price = params[:price]
      owner = @session_user.working_for
      quantity = params[:quantity]
      description = params[:quantity]
      filename = save_image(params[:image_file])
      item = Item.created(name, price, owner, quantity, description, filename)
      unless item.is_valid
        flash[:error] = item.errors
        redirect "/home/new"
      end
      @session_user.working_for.create_item(params[:name], Integer(price), Integer(quantity), params[:description], filename)
      flash[:notice] = "Item #{params[:name]} has been created"
      redirect "/home/items"
    end

    get "/item/:id/image" do
      redirect '/index' unless session[:id]
      path = Item.get_item(params[:id]).image
      if path == ""
        send_file(File.join(FileUtils::pwd, "public/images/item_pix/placeholder_item.jpg"))
      else
        send_file(path)
      end
    end

    post '/change/:itemid' do
      redirect '/index' unless session[:id]
      filename = save_image(params[:image_file])
      test_item = Item.created(params[:name], params[:price], @session_user.working_for, params[:quantity], params[:description], filename)
      unless test_item.is_valid
        flash[:error] = test_item.errors
        redirect "/home/edit_item/#{params[:itemid]}"
      else
        item = Item.get_item(params[:itemid])
        item.edit(params[:name],Integer(params[:price]),Integer(params[:quantity]),params[:description], filename)
        flash[:notice] = "#{params[:name]} has been changed"
        redirect "/home/items"
      end
    end

    get '/changestate/:itemid/activation' do
      redirect '/index' unless session[:id]
      if Item.get_item(params[:itemid]).is_owner?(@session_user.working_for.id)
        @item = Item.get_item(params[:itemid])
        haml :activation_confirm
      else
        redirect '/'
      end
    end

    post '/changestate/:id/setactive' do
      redirect '/index' unless session[:id]
      id = params[:id]
      owner = Item.get_item(id).owner
      item = Item.get_item(id)
      if(TimeHandler.validTime?(params[:exp_date], params[:exp_time]))
        unless((params[:exp_date].eql?("") and params[:exp_time].eql?("")))
          item.expiration_date= TimeHandler.parseTime(params[:exp_date], params[:exp_time])
        end
        owner.activate_item(id)
        flash[:notice] = "#{item.name} has been activated"
      else
        flash[:error] = "You did not put in a valid Time"
      end
      redirect "/home/items"
    end

    post '/changestate/:id/setinactive' do
      redirect '/index' unless session[:id]
      id = params[:id]
      owner = Item.get_item(id).owner
      owner.deactivate_item(id)
      flash[:notice] = "#{Item.get_item(id).name} has been deactivated"
      redirect "/home/items"
    end

    post '/buy/:id/:timestamp' do
      redirect '/index' unless session[:id]
      id = params[:id]
      unless Item.valid_integer?(params[:quantity])
        flash[:error] = "Please choose a valid quantity of items."
        redirect "#{back}"
      end
      quantity = Integer(params[:quantity])
      item = Item.get_item(id)
      old_user = item.owner
      user = session[:id]
      new_user = User.get_user(user)
      if (Integer(params[:timestamp])-item.timestamp)!=0
        flash[:error] = "#{item.name} has been edited while you were buying it"
        redirect "#{back}"
      end
      unless item.is_active?
        flash[:error] = "#{item.name} is no longer active."
        redirect "#{back}"
      end
      unless new_user.buy_new_item(item, quantity)
        flash[:error] = "You don't have enough credits to buy #{quantity} piece/s of #{item.name}"
        redirect "#{back}"
      end
      flash[:notice] = "You have bought #{quantity} piece/s of #{item.name}"
      redirect "/home"
    end

    post '/items/:id/delivered' do
      redirect '/index' unless session[:id]
      items = Models::Holding.get_all.select {|s|
        s.item.id.to_s.eql?(params[:id].to_s) }
      item = items.first
      item.itemReceived
      flash[:notice] = "Transfer completed. Would You like to rate #{item.seller.name}?"
      redirect "/rate/#{item.seller.id}"
    end
  end
end