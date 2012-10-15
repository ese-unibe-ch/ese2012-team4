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

    get '/home/active' do
      redirect '/index' unless session[:id]
      haml :home_all_items, :locals => {:page_name => "Your items", :error => nil}
    end

    get '/home/inactive' do
      redirect '/index' unless session[:id]
      haml :home_inactive, :locals => {:page_name => "Inactive items", :error => nil}
    end

    get '/home/new' do
      redirect '/index' unless session[:id]
      @item = Item.created("", "", "", "", "");
      haml :home_new, :locals =>{:action => "create", :button => "Create", :page_name => "New Item", :error => nil}
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
        haml :home_new, :locals => {:action => "change/#{params[:itemid]}", :button => "Save changes", :page_name => "Edit Item", :error => nil}
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
            haml :home_new, :locals => {:action => "edit_item/#{params[:itemid]}", :button => "Edit", :page_name => "Edit Item", :error => "Your quantity is not a valid number!"}
          when "not_a_number"
            haml :home_new, :locals => {:action => "edit_item/#{params[:itemid]}", :button => "Edit", :page_name => "Edit Item", :error => "Your price is not a valid number!"}
          when "no_name"
            haml :home_new, :locals => {:action => "edit_item/#{params[:itemid]}", :button => "Edit", :page_name => "Edit Item", :error => "You have to choose a name for your item!"}
        end
      else
        redirect "/"
      end
    end

    get '/items' do
      redirect '/index' unless session[:id]
      @all_items = Item.get_all(@session_user.name) # could possibly be id instead of name(merge)
      haml :items, :locals => {:page_name => "Items", :error => nil }
    end

    get '/items/:error_msg' do
      redirect '/index' unless session[:id]
      @all_items = Item.get_all(@session_user.name)
      case params[:error_msg]
        when "not_enough_credits"
          haml :items, :locals => {:page_name => "Items", :error => "Not enough credits!" }
        when "out_of_sync"
          haml :items, :locals => {:page_name => "Items", :error => "Item has been edited while you tried to buy it!" }
      end
    end

    get '/item/:itemid' do
      redirect '/index' unless session[:id]
      id = params[:itemid]
      @item = Item.get_item(id)
      haml :item_id, :locals => {:page_name => "Item #{@item.name}", :error => nil}
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
      redirect "/home/active"
    end

    get '/create/:error_msg' do
      redirect '/index' unless session[:id]
      @item = Item.created("","","","1")
      case params[:error_msg]
        when "not_a_number"
          haml :home_new, :locals =>{:action => "create", :button => "Create", :page_name => "New Item", :error => "Please choose a valid number!"}
        when "no_name"
          haml :home_new, :locals =>{:action => "create", :button => "Create", :page_name => "New Item", :error => "You have to choose a name for your item!"}
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
      redirect "/home/active"
    end

    post '/changestate/:id/setactive' do
      redirect '/index' unless session[:id]
      id = params[:id]
      Item.get_item(id).active = true
      redirect "/home/active"
    end

    post '/changestate/:id/setinactive' do
      redirect '/index' unless session[:id]
      id = params[:id]
      Item.get_item(id).active = false
      redirect "/home/active"
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
      redirect "/home/active"
    end

  end
end