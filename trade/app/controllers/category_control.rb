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
  class CategoryControl < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor
    use Rack::Flash

    before do
      @session_user = User.get_user(session[:id])
    end

    def authenticate!
      redirect "/index" unless session[:id]
    end

    get '/new_category' do
      authenticate!

      @supercategory = Category.get_supercategory
      haml :create_category
    end

    post '/create/category' do
      authenticate!

      supercat = Category.by_name(params[:category])
      unless supercat.nil?
        if supercat.get_names.include? params[:name]
          flash[:error] = "Category already exists.\n"
        else
          new_cat = Category.new(params[:name])
          supercat.add(new_cat)
          flash[:notice] = "Category #{params[:name]} successfully created!"
        end
      end
      redirect '/home/items'
    end

    post '/switch_category' do
      authenticate!
      redirect "/category/#{params[:category]}/1"
    end

    get '/category/:category/:page' do
      authenticate!

      order_by = params["order_by"] || 'name'
      order_direction = params["order_direction"] || 'asc'
      items_per_page = 10
      page = params[:page].to_i
      cat = Category.by_name(params[:category])
      items_of_cat = cat.get_offers(@session_user.working_for.name, {:order_by => order_by, :order_direction => order_direction})
      if order_direction == 'asc'      
        items = items_of_cat.sort{ |a,b| a.send(order_by) <=> b.send(order_by) }
      else
        items = items_of_cat.sort{ |a,b| b.send(order_by) <=> a.send(order_by) }
      end
      (items.size%items_per_page)==0? page_count = (items.size/items_per_page).to_i : page_count = (items.size/items_per_page).to_i+1
      @items = []
      for i in ((page-1)*items_per_page)..(page*items_per_page)-1
        @items<<items[i] unless items[i].nil?
      end
      @supercategory = Category.get_supercategory
      @selected = cat
      haml :items, :locals => {:title => 'All Items', :page => page, :page_count => page_count}
    end
  end
end
