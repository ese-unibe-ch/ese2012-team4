def relative(path)
  File.join(File.expand_path(File.dirname(__FILE__)), path)
end
require 'rubygems'
require 'require_relative'
require 'sinatra/base'
require 'haml'
require 'sinatra/content_for'
require_relative('../models/module/user')
require_relative('../models/module/item')

include Models

module Controllers
  class ItemControl < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor

    before do
      @session_user = User.get_user(session[:id])
    end

    get '/home/items' do
      redirect '/index' unless session[:id]
      haml :user_items, :locals => {:page_name => "My items", :error => nil}
    end

    get '/home/new' do
      redirect '/index' unless session[:id]
      @item = Item.created("", "", "", "", "");
      haml :item_edit, :locals =>{:action => "create", :button => "Create", :page_name => "New Item", :error => nil}
    end

    get '/home/edit_item/:itemid' do
      redirect '/index' unless session[:id]
      if Item.get_item(params[:itemid]).is_owner?(@session_user.id)

        @item = Item.get_item(params[:itemid])
        #RB: Not needed, if we assume that the system is in a valid state before
        #unless Item.valid_integer?(item_price)
        #  redirect "/home/edit_item/#{params[:itemid]}/not_a_number"
        #end

        # MW: To do: Get the right params.
        haml :item_edit, :locals => {:action => "change/#{params[:itemid]}", :button => "Save changes", :page_name => "Edit Item", :error => nil}
      else
        redirect "/"
      end
    end

    get '/home/edit_item/:itemid/:error_msg' do
      redirect '/index' unless session[:id]
      if Item.get_item(params[:itemid]).is_owner?(@user.name)
        @item = Item.get_item(params[:itemid])

        case params[:error_msg]
          when "not_valid_quantity"
            haml :item_edit, :locals => {:action => "edit_item/#{params[:itemid]}", :button => "Edit", :page_name => "Edit Item", :error => "Your quantity is not a valid number!"}
          when "not_a_number"
            haml :item_edit, :locals => {:action => "edit_item/#{params[:itemid]}", :button => "Edit", :page_name => "Edit Item", :error => "Your price is not a valid number!"}
          when "no_name"
            haml :item_edit, :locals => {:action => "edit_item/#{params[:itemid]}", :button => "Edit", :page_name => "Edit Item", :error => "You have to choose a name for your item!"}
        end
      else
        redirect "/"
      end
    end

    get '/items' do
      redirect '/index' unless session[:id]
      @all_items = Item.get_all(@session_user.name)
      haml :all_items, :locals => {:page_name => "Items", :error => nil }
    end

    get '/items/:error_msg' do
      redirect '/index' unless session[:id]
      @all_items = Item.get_all(@session_user.name)
      case params[:error_msg]
        when "not_enough_credits"
          haml :all_items, :locals => {:page_name => "Items", :error => "Not enough credits!" }
        when "out_of_sync"
          haml :all_items, :locals => {:page_name => "Items", :error => "Item has been edited while you tried to buy it!" }
      end
    end

    get '/item/:itemid' do
      redirect '/index' unless session[:id]
      id = params[:itemid]
      @item = Item.get_item(id)
      haml :item_page, :locals => {:page_name => "Item #{@item.name}", :error => nil}
    end

    get '/item/:itemid/:error' do
      redirect '/index' unless session[:id]
      id = params[:itemid]
      @item = Item.get_item(id)

      case params[:error]
        when "not_enough_credits"
          haml :item_page, :locals => {:page_name => "Item #{@item.name}", :error => "Not enough credits!"}
      end
    end



    post '/create' do
      redirect '/index' unless session[:id]
      price = params[:price]
      quantity = params[:quantity]

      unless Item.valid_integer?(price) & Item.valid_integer?(quantity)
        redirect "create/not_a_number"
      end
      #error handling for empty names or whitespaces (strip removes all kind of whitespaces, but not the first space)
      unless params[:name].strip.delete(' ')!=""
        redirect '/create/no_name'
      end
      @session_user.create_item(params[:name], Integer(price), Integer(quantity), params[:description])
      # MW: maybe "User.by_name" might be somewhat more understandable
      redirect "/home/items"
    end

    get '/create/:error_msg' do
      redirect '/index' unless session[:id]
      @item = Item.created("","","","1")
      case params[:error_msg]
        when "not_a_number"
          haml :item_edit, :locals =>{:action => "create", :button => "Create", :page_name => "New Item", :error => "Please choose a valid number!"}
        when "no_name"
          haml :item_edit, :locals =>{:action => "create", :button => "Create", :page_name => "New Item", :error => "You have to choose a name for your item!"}
      end
    end

    post '/change/:itemid' do
      redirect '/index' unless session[:id]
      #error handling for empty names or whitespaces (strip removes all kind of whitespaces, but not the first space)
      unless params[:name].strip.delete(' ')!=""
        redirect "/home/edit_item/#{params[:itemid]}/no_name"
      end
      item = Item.get_item(params[:itemid])
      price = params[:price]
      quantity = params[:quantity]
      unless Item.valid_integer?(String(price)) & Item.valid_integer?(quantity)
        redirect "/home/edit_item/#{params[:itemid]}/not_a_number"
      end
      item.edit(params[:name],Integer(price),Integer(quantity),params[:description])
      redirect "/home/items"
    end

    post '/changestate/:id/setactive' do
      redirect '/index' unless session[:id]
      id = params[:id]
      owner = Item.get_item(id).owner
      owner.activate_item(id)
      redirect "/home/items"
    end

    post '/changestate/:id/setinactive' do
      redirect '/index' unless session[:id]
      id = params[:id]
      owner = Item.get_item(id).owner
      owner.deactivate_item(id)
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
        if(back.include? '/out_of_sync')
          redirect '#back'
        else
          redirect "#{back}/out_of_sync"
        end
      end
      unless new_user.buy_new_item?(item, quantity)
        if back.include? '/not_enough_credits'
          redirect "#{back}"
        else
          redirect "#{back}/not_enough_credits"
        end
      end
      redirect "/home/items"
    end

  end
end