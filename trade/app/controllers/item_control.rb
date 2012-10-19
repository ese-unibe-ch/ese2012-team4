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

    before do
      @session_user = User.get_user(session[:id])
    end

    get '/home/items' do
      redirect '/index' unless session[:id]
      haml :user_items, :locals => {:page_name => "My items"}
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

    get '/items' do
      redirect '/index' unless session[:id]
      @all_items = Item.get_all(@session_user.name)
      haml :all_items, :locals => {:page_name => "Items" }
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
        FileUtils::rm(filename)
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
      send_file(path)
    end

    post '/change/:itemid' do
      redirect '/index' unless session[:id]

      filename = save_image(params[:image_file])
      test_item = Item.created(params[:name], params[:price], @session_user, params[:quantity], params[:description], filename)
      unless test_item.is_valid
        FileUtils::rm(filename)
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