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
      @user = User.get_user(session[:username])
    end

    get '/home/active' do
      redirect '/index' unless session[:username]
      haml :home_all_items, :locals => {:user => @user, :page_name => "Your items", :error => nil}
    end

    get '/home/inactive' do
      redirect '/index' unless session[:username]
      haml :home_inactive, :locals => {:inactive_items => @user.list_items_inactive, :page_name => "Inactive items", :error => nil}
    end

    get '/home/new' do
      redirect '/index' unless session[:username]
      haml :home_new, :locals =>{:action => "create", :name => "", :price => "", :description =>"", :quantity =>"1", :button => "Create", :page_name => "New Item", :error => nil}
    end

    get '/home/edit_item/:itemid' do
      redirect '/index' unless session[:username]
      if Item.get_item(params[:itemid]).is_owner?(@user.name)

        item = Item.get_item(params[:itemid])
        item_name = item.name
        item_price = item.price
        item_description = item.description
        item_quantity = item.quantity
        unless Item.valid_price?(String(item_price))
          redirect "/home/edit_item/#{params[:itemid]}/not_a_number"
        end

        # MW: To do: Get the right params.
        haml :home_new, :locals => {:action => "edit_item/#{params[:itemid]}", :name => item_name, :price => item_price, :description => item_description, :quantity =>item_quantity, :button => "Save changes", :page_name => "Edit Item", :error => nil}
      else
        redirect "/"
      end
    end

    get '/home/edit_item/:itemid/:error_msg' do
      redirect '/index' unless session[:username]
      if Item.get_item(params[:itemid]).is_owner?(@user.name)
        item = Item.get_item(params[:itemid])
        item_name = item.name
        price = item.price
        description = item.description

        case params[:error_msg]
          when "not_a_number"
            haml :home_new, :locals => {:action => "edit_item/#{params[:itemid]}", :name => item_name, :price => price, :description => description, :button => "Edit", :page_name => "Edit Item", :error => "Your price is not a valid number!"}
          when "no_name"
            haml :home_new, :locals => {:action => "edit_item/#{params[:itemid]}", :name => item_name, :price => price, :description => description, :button => "Edit", :page_name => "Edit Item", :error => "You have to choose a name for your item!"}
        end
      else
        redirect "/"
      end
    end

    get '/items' do
      redirect '/index' unless session[:username]
      haml :items, :locals => {:all_items => Item.get_all(@user.name), :page_name => "Items", :error => nil }
    end

    get '/items/:error_msg' do
      redirect '/index' unless session[:username]
      case params[:error_msg]
        when "not_enough_credits"
          haml :items, :locals => {:all_items => Item.get_all(@user.name), :page_name => "Items", :error => "Not enough credits!" }
        when "out_of_sync"
          haml :items, :locals => {:all_items => Item.get_all(@user.name), :page_name => "Items", :error => "Item has been edited while you tried to buy it!" }
      end
    end

    post '/create' do
      redirect '/index' unless session[:username]
      user = session[:username]
      price = params[:price]

      unless Item.valid_price?(price)
        redirect "create/not_a_number"
      end
      #error handling for empty names or whitespaces (strip removes all kind of whitespaces, but not the first space)
      unless params[:name].strip.delete(' ')!=""
        redirect '/create/no_name'
      end
      User.get_user(user).create_item(params[:name], Integer(params[:price]), params[:description])
      # MW: maybe "User.by_name" might be somewhat more understandable
      redirect "/home/active"
    end

    get '/create/:error_msg' do
      redirect '/index' unless session[:username]
      case params[:error_msg]
        when "not_a_number"
          haml :home_new, :locals =>{:action => "create", :name => "", :price => "", :description =>"", :quantity =>"1", :button => "Create", :page_name => "New Item", :error => "Your price is not a valid number!"}
        when "no_name"
          haml :home_new, :locals =>{:action => "create", :name => "", :price => "", :description =>"", :quantity =>"1", :button => "Create", :page_name => "New Item", :error => "You have to choose a name for your item!"}
      end
    end

    post '/edit_item/:itemid' do
      redirect '/index' unless session[:username]
      #error handling for empty names or whitespaces (strip removes all kind of whitespaces, but not the first space)
      unless params[:name].strip.delete(' ')!=""
        redirect "/home/edit_item/#{params[:itemid]}/no_name"
      end
      item = Item.get_item(params[:itemid])
      price = params[:price]
      unless Item.valid_price?(String(price))
        redirect "/home/edit_item/#{params[:itemid]}/not_a_number"

      end
      item.edit(params[:name],params[:price],params[:quantity],params[:description])
      redirect "/home/active"
    end

    post '/changestate/:id/setactive' do
      redirect '/index' unless session[:username]
      id = params[:id]
      Item.get_item(id).active = true
      redirect "/home/active"
    end

    post '/changestate/:id/setinactive' do
      redirect '/index' unless session[:username]
      id = params[:id]
      Item.get_item(id).active = false
      redirect "/home/active"
    end

    post '/buy/:id/:timestamp' do
      redirect '/index' unless session[:username]
      id = params[:id]
      quantity = params[:quantity].to_i
      item = Item.get_item(id)
      old_user = item.owner
      user = session[:username]
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