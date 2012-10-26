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
      haml :search , :locals => {:page_name => "Search"}
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
      items_per_page = 20
      page = params[:page].to_i
      items = @@item_map[session[:id]]
      (items.size%items_per_page)==0? page_count = (items.size/items_per_page).to_i : page_count = (items.size/items_per_page).to_i+1
      if page_count ==0
        page_count=1
      end
      redirect 'search/result/1' unless 0<params[:page].to_i and params[:page].to_i<page_count+1
      @all_items = []
      for i in ((page-1)*items_per_page)..(page*items_per_page)-1
        @all_items<<items[i] unless items[i].nil?
      end
      haml :search_result, :locals=> {:page_name => "result", :page => page, :page_count =>page_count}
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
      active_items = @session_user.list_items
      (active_items.size%items_per_page)==0? active_page_count = (active_items.size/items_per_page).to_i : active_page_count = (active_items.size/items_per_page).to_i+1
      if active_items.size==0
        active_page_count=1
      end
      redirect 'home/items/1/1' unless 0<params[:active].to_i and params[:active].to_i<active_page_count+1
      inactive_items = @session_user.list_items_inactive
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
      haml :user_items, :locals => {:page_name => "My items", :active_page =>active, :active_page_count =>active_page_count, :inactive_page =>inactive, :inactive_page_count => inactive_page_count}
    end

    get '/home/items' do
      redirect '/index' unless session[:id]
      redirect '/home/items/1/1'
    end

    get '/home/new' do
      redirect '/index' unless session[:id]
      @item = Item.created("", "", "", "", "");
      haml :item_edit, :locals =>{:action => "create", :button => "Create", :page_name => "New Item"}
    end

    get '/home/edit_item/:itemid' do
      redirect '/index' unless session[:id]
      if Item.get_item(params[:itemid]).is_owner?(@session_user.id)

        @item = Item.get_item(params[:itemid])
        #RB: Not needed, if we assume that the system is in a valid state before
        #unless Item.valid_integer?(item_price)
        #  redirect "/home/edit_item/#{params[:itemid]}/not_a_number"
        #end

        haml :item_edit, :locals => {:action => "change/#{params[:itemid]}", :button => "Save changes", :page_name => "Edit Item"}
      else
        redirect "/"
      end
    end

    get '/items/:page' do
      redirect '/index' unless session[:id]

      items_per_page = 20
      page = params[:page].to_i
      items = Item.get_all(@session_user.name)
      (items.size%items_per_page)==0? page_count = (items.size/items_per_page).to_i : page_count = (items.size/items_per_page).to_i+1
      redirect 'items/1' unless 0<params[:page].to_i and params[:page].to_i<page_count+1
      @all_items = []
      for i in ((page-1)*items_per_page)..(page*items_per_page)-1
        @all_items<<items[i] unless items[i].nil?
      end
      haml :all_items, :locals => {:page_name => "Items", :page => page, :page_count => page_count}
    end

    get '/items' do
      redirect '/index' unless session[:id]
      redirect '/items/1'
    end

    get '/item/:itemid' do
      redirect '/index' unless session[:id]
      id = params[:itemid]
      @item = Item.get_item(id)
      haml :item_page, :locals => {:page_name => "Item #{@item.name}"}
    end

    post '/create' do
      redirect '/index' unless session[:id]
      name = params[:name]
      price = params[:price]
      owner = @session_user
      quantity = params[:quantity]
      description = params[:quantity]

      filename = save_image(params[:image_file])

      item = Item.created(name, price, owner, quantity, description, filename)
      unless item.is_valid
        flash[:error] = item.errors
        redirect "/home/new"
      end
      
      @session_user.create_item(params[:name], Integer(price), Integer(quantity), params[:description], filename)
      flash[:notice] = "Item has been created"
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
      test_item = Item.created(params[:name], params[:price], @session_user, params[:quantity], params[:description], filename)
      unless test_item.is_valid
        flash[:error] = test_item.errors
        redirect "/home/edit_item/#{params[:itemid]}"
      else
        item = Item.get_item(params[:itemid])
        item.edit(params[:name],Integer(params[:price]),Integer(params[:quantity]),params[:description], filename)
        flash[:notice] = "Item has been changed"
        redirect "/home/items"
      end
    end

    post '/changestate/:id/setactive' do
      redirect '/index' unless session[:id]
      id = params[:id]
      owner = Item.get_item(id).owner
      owner.activate_item(id)
      flash[:notice] = "Item has been activated"
      redirect "/home/items"
    end

    post '/changestate/:id/setinactive' do
      redirect '/index' unless session[:id]
      id = params[:id]
      owner = Item.get_item(id).owner
      owner.deactivate_item(id)
      flash[:notice] = "Item has been deactivated"
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
        flash[:error] = "Item has been edited while you were buying it"
        redirect "#{back}"
      end
      unless new_user.buy_new_item(item, quantity)
        flash[:error] = "You don't have enough credits"
        redirect "#{back}"
      end
      flash[:notice] = "You have bought the item"
      redirect "/home/items"
    end
  end
end