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
  class Creator < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor

    post '/create' do
      unless session[:username].nil?
        username = session[:username]
        #error handling for invalid prices
        unless params[:price].length == params[:price].count("0-9")
          redirect '/create/not_a_number'

        end
        #error handling for empty names or whitespaces (strip removes all kind of whitespaces, but not the first space)
        unless params[:name].strip.delete(' ')!=""
          redirect '/create/no_name'
        end
        User.get_user(username).create_item(params[:name], Integer(params[:price]), params[:description])
          # MW: maybe "User.by_name" might be somewhat more understandable
        redirect "/home/inactive"
      else
        redirect "/"
      end
    end

    get '/create/:error_msg' do
      case params[:error_msg]
        when "not_a_number"
          haml :home_new, :locals =>{:action => "create", :name => "", :price => "", :description =>"", :button => "Create", :page_name => "New Item", :error => "Your price is not a valid number!"}
        when "no_name"
          haml :home_new, :locals =>{:action => "create", :name => "", :price => "", :description =>"", :button => "Create", :page_name => "New Item", :error => "You have to choose a name for your item!"}
      end
    end

    post '/edit_item/:itemid' do
      #error handling for empty names or whitespaces (strip removes all kind of whitespaces, but not the first space)
      unless params[:name].strip.delete(' ')!=""
        redirect "/home/edit_item/#{params[:itemid]}/no_name"
      end
      item = Item.get_item(params[:itemid])
      item.name = params[:name]
      #error handling for invalid prices
      if params[:price].length != params[:price].count("0-9")
        redirect "/home/edit_item/#{params[:itemid]}/not_a_number"
      else
        item.price = Integer(params[:price])
      end
      item.description = params[:description]
      redirect "/home/inactive"
    end

    get '/home/edit_item/:itemid/:error_msg' do
      case params[:error_msg]
        when "not_a_number"
          item = Item.get_item(params[:itemid])
          haml :home_new, :locals => {:action => "edit_item/#{params[:itemid]}", :name => item.name, :price => item.price, :description => item.description, :button => "Edit", :page_name => "Edit Item", :error => "Your price is not a valid number!"}
        when "no_name"
          item = Item.get_item(params[:itemid])
          haml :home_new, :locals => {:action => "edit_item/#{params[:itemid]}", :name => item.name, :price => item.price, :description => item.description, :button => "Edit", :page_name => "Edit Item", :error => "You have to choose a name for your item!"}
      end

    end

    get '/changestate/:id/setactive' do
      if not session[:username].nil?
        id = params[:id]
        Item.get_item(id).active = true
        redirect "/home/inactive"
      else
        redirect "/"
      end
    end

    get '/changestate/:id/setinactive' do
      if not session[:username].nil?
        id = params[:id]
        Item.get_item(id).active = false
        redirect "/home/active"
      else
        redirect "/"
      end
    end

    get '/buy/:id' do               # TODO: change to post!
      if not session[:username].nil?
        id = params[:id]
        item = Item.get_item(id)
        old_user = item.owner
        username = session[:username]
        new_user = Models::User.get_user(username)
        if new_user.buy_new_item?(item)
          old_user.remove_item(item)
        else
          if back.include? '/not_enough_credits'
            redirect "#{back}"
          else
            redirect "#{back}/not_enough_credits"
          end
        end
        redirect "/home/inactive"
      else
        redirect "/"
      end
    end

  end
end