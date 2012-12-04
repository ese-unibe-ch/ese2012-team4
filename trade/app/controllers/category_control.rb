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

    get '/new_category' do
      redirect '/index' unless session[:id]
      @supercategory = Category.get_supercategory
      haml :create_category
    end

    post '/create/category' do
      redirect '/index' unless session[:id]
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
  end
end