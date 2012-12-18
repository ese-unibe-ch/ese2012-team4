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
require_relative('../models/module/category')
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

    def authenticate!
      redirect "/index" unless session[:id]
    end

    get '/search' do
      authenticate!

      haml :search
    end

    post '/search/query' do
      authenticate!

      input = params[:search]
      @@item_map[session[:id]]= Item.search(input,User.get_user(session[:id]).working_for)
      redirect '/search/result/1'
    end

    get '/search/webservice/:query' do
      authenticate!

      # limit to the first four results
      result = Item.search(params[:query], User.get_user(session[:id]).working_for).slice(0,4)
      result.map!{ |item| item.to_json }
      json_string = '{"results": ['
      json_string += result.join(", ")
      json_string += ']}'
      json_string
    end

    get '/search/result/:page' do
      authenticate!

      redirect '/search' if @@item_map[session[:id]].nil?
      items_per_page = 10
      page = params[:page].to_i

      order_by = params["order_by"] || 'name'
      order_direction = params["order_direction"] || 'asc'

      if order_direction == 'asc'
        items = @@item_map[session[:id]].sort{ |a,b| a.send(order_by) <=> b.send(order_by) }
      else
        items = @@item_map[session[:id]].sort{ |a,b| b.send(order_by) <=> a.send(order_by) }
      end
      (items.size%items_per_page)==0? page_count = (items.size/items_per_page).to_i : page_count = (items.size/items_per_page).to_i+1
      if page_count ==0
        page_count=1
      end
      redirect 'search/result/1' unless 0<params[:page].to_i and params[:page].to_i<page_count+1

      @items = []
      @selected = Category.get_supercategory
      @supercategory = Category.get_supercategory
      for i in ((page-1)*items_per_page)..(page*items_per_page)-1
        @items<<items[i] unless items[i].nil?
      end
      haml :items, :locals=> {:title => 'Search Result', :page => page, :page_count =>page_count}
    end

    get '/search/result' do
      authenticate!

      redirect '/search/result/1'
    end

    get '/home/items/:active/:inactive' do
      authenticate!

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
      @auctions = @session_user.working_for.offers.select{|s| s.auction}
      haml :user_items, :locals => {:active_page =>active, :active_page_count =>active_page_count, :inactive_page =>inactive, :inactive_page_count => inactive_page_count}
    end

    get '/home/items' do
      authenticate!

      redirect '/home/items/1/1'
    end

    get '/home/new' do
      authenticate!

      @item = Item.created("", "", "", "", "");
      @supercategory = Category.get_supercategory
      haml :item_edit, :locals =>{:action => "create", :button => "Create"}
    end

    get '/home/edit_item/:itemid' do
      authenticate!

      if Item.get_offer(params[:itemid]).is_owner?(@session_user.working_for.id)
        @item = Item.get_offer(params[:itemid])
        @supercategory = Category.get_supercategory
        haml :item_edit, :locals => {:action => "change/#{params[:itemid]}", :button => "Save changes"}
      else
        redirect "/"
      end
    end

    get '/items/:page' do
      authenticate!

      order_by = params["order_by"] || 'name'
      order_direction = params["order_direction"] || 'asc'
      items_per_page = 10
      page = params[:page].to_i
      items = Item.get_all(@session_user.working_for.name, {:order_by => order_by, :order_direction => order_direction})
      (items.size%items_per_page)==0? page_count = (items.size/items_per_page).to_i : page_count = (items.size/items_per_page).to_i+1
      redirect 'items/1' unless 0<params[:page].to_i and params[:page].to_i<page_count+1
      @items = []
      for i in ((page-1)*items_per_page)..(page*items_per_page)-1
        @items<<items[i] unless items[i].nil?
      end
      @supercategory = Category.get_supercategory
      @selected = Category.get_supercategory
      haml :items, :locals => {:title => 'All Items', :page => page, :page_count => page_count}
    end

    get '/items' do
      authenticate!

      redirect '/items/1'
    end

    get '/item/:itemid' do
      authenticate!

      id = params[:itemid]
      @item = Offer.get_offer(id)
      haml :item_page
    end

    post '/create' do
      authenticate!

      name = params[:name]
      price = params[:price]
      owner = @session_user.working_for
      quantity = params[:quantity]
      description = params[:description]
      filename = save_image(params[:image_file])
      item = Item.created(name, price, owner, quantity, description, filename)
      item.currency = params[:currency]
	    item.category = Category.by_name(params[:category])

      if self.has_errors(item)
        @item = item
        @supercategory = Category.get_supercategory
        haml :item_edit, :locals =>{:action => "create", :button => "Create"}
      else
        item = @session_user.create_item(params[:name], Integer(price), Integer(quantity), params[:description], filename)
        @session_user.edit_item(item, params[:name],Integer(params[:price]),Integer(params[:quantity]),params[:currency],params[:description], filename)
        item.category = Category.by_name(params[:category])
        if params[:permanent]=="no"
          item.permanent = false
        end
        if params[:permanent]=="yes"
          item.permanent = true
        end
        flash[:notice] = "Item #{params[:name]} has been created"
        redirect "/home/items"
      end
    end

    get "/item/:id/image" do
      authenticate!

      path = Item.get_offer(params[:id]).image
      if path == ""
        send_file(File.join(FileUtils::pwd, "public/images/item_pix/placeholder_item.jpg"))
      else
        send_file(path)
      end
    end

    post '/change/:itemid' do
      authenticate!

      filename = save_image(params[:image_file])
      test_item = Item.created(params[:name], params[:price], @session_user.working_for, params[:quantity], params[:description], filename)
      test_item.category = Category.by_name(params[:category])
      test_item.currency = params[:currency]
      if self.has_errors(test_item)
        redirect "/home/edit_item/#{params[:itemid]}"
      else
        item = Item.get_offer(params[:itemid])
        owner = item.owner
        viewer = User.get_user(session[:id])
        redirect '/index' unless owner == viewer.working_for
        @session_user.edit_item(item, params[:name],Integer(params[:price]),Integer(params[:quantity]),params[:currency],params[:description], filename)
        item.category = Category.by_name(params[:category])
        if params[:permanent]=="no"
          item.permanent = false
        end
        if params[:permanent]=="yes"
          item.permanent = true
        end
        flash[:notice] = "#{params[:name]} has been changed"
        redirect "/home/items"
      end
    end

    post '/permanent/:itemid' do
      authenticate!

      item = Offer.get_offer(params[:itemid])
      unless item.nil?
        owner = item.owner
        viewer = User.get_user(session[:id])
        redirect '/index' unless owner == viewer.working_for
        if item.auction
          flash[:error] = "invalid action"
          redirect back
        end
        item.switch_permanent
        flash[:notice] = "successfully changed status"
      end
      redirect back
    end

    post '/restock/:itemid' do
      authenticate!

      item = Offer.get_offer(params[:itemid])
      unless item.nil?
        owner = item.owner
        viewer = User.get_user(session[:id])
        redirect '/index' unless owner == viewer.working_for
        redirect back unless item.permanent
        item.restock(params[:quantity])
        redirect back
      end
    end

    get '/changestate/:itemid/activation' do
      authenticate!

      if Item.get_offer(params[:itemid]).is_owner?(@session_user.working_for.id)
        @item = Item.get_offer(params[:itemid])
        haml :activation_confirm
      else
        redirect '/'
      end
    end

    post '/changestate/:id/setactive' do
      authenticate!

      id = params[:id]
      item = Item.get_offer(id)
      unless item.nil?
        owner = item.owner
        viewer = User.get_user(session[:id])
        redirect '/index' unless owner == viewer.working_for
        if(TimeHandler.validTime?(params[:exp_date], params[:exp_time]))
          unless((params[:exp_date].eql?("") and params[:exp_time].eql?("")))
            item.expiration_date= TimeHandler.parseTime(params[:exp_date], params[:exp_time])
          end
          @session_user.working_for.activate_item(id)
          flash[:notice] = "#{item.name} has been activated"
        else
          flash[:error] = "You did not put in a valid Time"
        end
      end
      redirect "/home/items"
    end

    post '/changestate/:id/setinactive' do
      authenticate!

      id = params[:id]
      item = Item.get_offer(id)
      unless item.nil?
        owner = item.owner
        viewer = User.get_user(session[:id])
        redirect '/index' unless owner == viewer.working_for
        @session_user.working_for.deactivate_item(id)
        flash[:notice] = "#{Item.get_offer(id).name} has been deactivated"
      end
      redirect "/home/items"
    end

    post '/buy/:id/:timestamp' do
      authenticate!

      id = params[:id]
      unless Item.valid_integer?(params[:quantity])
        flash[:error] = "Please choose a valid quantity of items."
        redirect back
      end
      quantity = Integer(params[:quantity])
      item = Item.get_offer(id)
      old_owner = item.owner
      if (Integer(params[:timestamp])-item.timestamp)!=0
        flash[:error] = "#{item.name} has been edited while you were buying it"
        redirect back
      end
      unless item.is_active?
        flash[:error] = "#{item.name} is no longer active."
        redirect back
      end

      if quantity>item.quantity
        flash[:error] = "There are not enough copies of #{item.name} available"
        @session_user.working_for.buy_new_item(item, quantity, @session_user) #for logging
        redirect back
      end

      unless @session_user.working_for.buy_new_item(item, quantity, @session_user)
        flash[:error] = "You don't have enough credits to buy #{quantity} piece/s of #{item.name}"
        redirect back
      end
      flash[:notice] = "You have bought #{quantity} piece/s of #{item.name}"
      redirect "/pending"
    end

    post '/items/:id/delivered' do
      authenticate!

      items = Models::Holding.find_by_id(params[:id].to_s)
      item = items.first

      redirect '/index' unless User.get_user(session[:id]).working_for == item.buyer and !item.locked

      item.item_received
      flash[:notice] = "Transfer completed. Would You like to rate #{item.seller.name}?"
      redirect "/rate/#{item.seller.id}"
    end

    post '/items/:id/unlock' do
      authenticate!

      items = Models::Holding.find_by_id(params[:id].to_s)
      item = items.first
      redirect '/index' unless User.get_user(session[:id]).working_for == item.seller
      item.locked = false
      redirect "/pending"
    end

    def has_errors(item)
      is_valid_item = catch(:invalid){item.is_valid}
      case is_valid_item
        when true
          false
        when :invalid_name then
          flash[:error] = "Item must have a name\n"
          true
        when :invalid_price then
          flash[:error] = "Price is not a valid number\n"
          true
        when :invalid_quantity then
          flash[:error] = "Quantity is not a valid number\n"
          true
        when :big_image then
          flash[:error] = "Image is heavier than 400kB\n"
          true
        when :no_valid_image_file then
          flash[:error] = "No valid image file selected\n"
          true
        when :invalid_currency then
          flash[:error] = "You need to set a Bitcoin wallet in your Profile to accept Bitcoins as payment"
          true
        else
          flash[:error] = "The item is not valid."
          true
      end
    end
  end
end
