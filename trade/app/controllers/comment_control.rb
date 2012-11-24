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

include Models

module Controllers
  class CommentControl < Sinatra::Base
    set :views, relative('../../app/views')
    helpers Sinatra::ContentFor
    use Rack::Flash

    before do
      @session_user = User.get_user(session[:id])
    end

    get "/comments/:item_id" do
      redirect "/index" unless session[:id]
      item_name = Item.get_offer(params[:item_id]).name
      @item = Item.get_offer(params[:item_id])
      haml :comments
    end

    get '/reply/:comment_id' do
      redirect "/index" unless session[:id]
      @comment = Comment.by_id(params[:comment_id])
      haml :reply
    end

    get '/comment/:item_id' do
      redirect "/index" unless session[:id]
      @item = Item.get_offer(params[:item_id])
      haml :create_comment
    end

    post '/answer/:comment_id' do
      redirect '/index' unless session[:id]
      comment = Comment.by_id(params[:comment_id])
      @session_user.working_for.answer_comment(comment, params[:reply])
      redirect "/comments/#{comment.correspondent_item.id}"
    end

    post '/create_comment/:item_id' do
      redirect '/index' unless session[:id]
      item = Item.get_offer(params[:item_id])
      @session_user.working_for.comment_item(item, params[:com])
      redirect "/comments/#{params[:item_id]}"
    end
  end
end