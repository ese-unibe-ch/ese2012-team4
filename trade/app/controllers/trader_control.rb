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
  class TraderControl < Sinatra::Base
    set :views, relative('../../app/views')
    set :public_folder, relative('../public')
    helpers Sinatra::ContentFor
    use Rack::Flash

    before do
      @session_user = User.get_user(session[:id])
    end

    get '/logout' do
      redirect '/index' unless session[:id]
      haml :logout
    end

    get '/home' do
      redirect '/index' unless session[:id]
      @activities = @session_user.get_watching_logs
      haml :home
    end

    get '/users' do
      redirect '/index' unless session[:id]
      @all_users = User.get_all("")
      haml :users
    end

    get '/selectusers/:id' do
      redirect '/index' unless session[:id]
      @all_users = User.get_all("")
      @org = User.get_user(params[:id])
      haml :selectusers
    end

    get '/selectadmins/:id' do
      redirect '/index' unless session[:id]
      @org = User.get_user(params[:id])
      @all_users = @org.member_list
      haml :selectadmins
    end

    post '/setuser/:org_id/:user_id' do
      redirect '/index' unless session[:id]
      org = User.get_user(params[:org_id])
      user = User.get_user(params[:user_id])
      redirect "#{back}" unless (!user.organization and org.organization)
      if org.member_list.include?(user)
        org.delete_member(user)
      else
        org.add_member(user)
      end
      redirect "#{back}"
    end

    post '/setadmin/:org_id/:user_id' do
      redirect '/index' unless session[:id]
      org = User.get_user(params[:org_id])
      user = User.get_user(params[:user_id])
      redirect "#{back}" unless (!user.organization and org.organization)
      if org.admin_list.include?(user)
        org.delete_admin(user)
      else
        org.add_admin(user)
      end
      redirect "#{back}"
    end

    get '/users/:id/:page' do
      redirect '/index' unless session[:id]
      @user = User.get_user(params[:id])
      items_per_page = 10
      page = params[:page].to_i
      items = @user.list_items
      (items.size%items_per_page)==0? page_count = (items.size/items_per_page).to_i : page_count = (items.size/items_per_page).to_i+1
      if(items.size==0)
        page_count=1;
      end
      redirect "users/#{params[:id]}/1" unless 0<params[:page].to_i and params[:page].to_i<page_count+1
      @all_items = []
      for i in ((page-1)*items_per_page)..(page*items_per_page)-1
        @all_items<<items[i] unless items[i].nil?
      end
      @auctions = @user.list_auctions
      haml :user_page, :locals => {:page => page, :page_count => page_count}
    end
    get '/users/:id' do
      redirect "/users/#{params[:id]}/1"
    end

    get "/user/:id/image" do
      redirect '/index' unless session[:id]
      path = User.get_user(params[:id]).image
      if path == ""
        send_file(File.join(FileUtils::pwd, "public/images/user_pix/placeholder_user.jpg"))
      else
        send_file(path)
      end
    end

    get "/rate/:id" do
      redirect '/index' unless session[:id]
      @user = User.get_user(params[:id])
      haml :rate_user
    end

    post "/rate/:id" do
      redirect '/index' unless session[:id]
      user = User.get_user(params[:id])
      user.add_rating(params[:rating]) unless params[:rating] == nil
      redirect "/home"
    end

    post "/unauthenticate" do
      redirect '/index' unless session[:id]
      session[:id] = nil
      #session['auth'] = false
      flash[:notice] = "You are now logged out"
      redirect "/"
    end

    get '/profile/:id' do
      @user =  User.get_user(params[:id])
      redirect '/index' unless (session[:id] or @user.id==session[:id])
      if User.get_user(params[:id]).organization
        redirect '/index' unless @user.admin_list.include?(User.get_user(session[:id]))
      end
      haml :profile
    end

    post "/change_profile/:id" do
      redirect '/index' unless session[:id]
      viewer = User.get_user(params[:id])
      if viewer.organization
        redirect '/index' unless viewer.admin_list.include?(User.get_user(session[:id]))
      else
        redirect '/index' unless viewer==User.get_user(session[:id])
      end
      filename = save_image(params[:image_file])
      test_user = User.created(viewer.name, "FdZ.(gJa)s'dFjKdaDGS+J1", params[:e_mail].strip, params[:description].split("\n"), filename)
      if self.has_errors(test_user,nil, nil, false)
        redirect back
      else
        viewer.wallet = params[:wallet]
        viewer.description = params[:description].split("\n")
        if filename != ""
          FileUtils.rm(viewer.image, :force => true)
          viewer.image = filename
        end
        viewer.e_mail = params[:e_mail].strip
        flash[:notice] = "Profile has been updated"
        redirect "/profile/#{params[:id]}"
      end
    end
    
    post "/change_password" do
      redirect '/index' unless session[:id]
      viewer = User.get_user(session[:id])
      if self.has_errors(viewer,params[:password_new], params[:password_check], false)
        redirect back
      end
      viewer.change_password(params[:password_new])
      flash[:notice] = "Password has been updated"
      redirect "/"
    end

    post "/switch_account_context" do
      redirect '/index' unless session[:id]
      viewer = User.get_user(session[:id])
      context = Trader.by_name(params[:context])
      viewer.working_for = context
      redirect "#{back}"
    end
    
    get '/pending' do
      redirect '/index' unless session[:id]
      @inbox = @session_user.working_for.pending_inbox
      @outbox = @session_user.working_for.pending_outbox
      haml :pending_items
    end

    get '/delete_link' do
      redirect '/index' unless session[:id]
      haml :delete_user
    end


    delete '/delete_account' do
      #delete user
      user = session[:id]
      User.get_user(user).delete
      #close session
      session[:id] = nil
      redirect '/index' unless session[:id]
      haml :logout
    end

    get '/wishlist' do
      redirect '/index' unless session[:id]
      haml :wishlist
    end

    post "/remove_from_wishlist/:itemid" do
      redirect '/index' unless session[:id]
      @item = Item.get_offer(params[:itemid])
      @session_user.working_for.remove_from_wishlist(@item)
      redirect "#{back}"
    end

    post "/add_to_wishlist/:itemid" do
      redirect '/index' unless session[:id]
      @item = Item.get_offer(params[:itemid])
      @session_user.working_for.add_to_wishlist(@item)
      redirect "#{back}"
    end

    post "/add_to_wishlist/:itemid" do
      redirect '/index' unless session[:id]
      id = params[:itemid]
      @item = Item.get_offer(id)
      unless @item.active == true
        flash[:error] = "Item has been deactivated"
        redirect "/items"
      end
      @session_user.working_for.add_to_wishlist(@item)
      flash[:notice] = "Item has been added to your wishlist"
      redirect "/wishlist"
    end

    get '/create_organization' do
      redirect '/index' unless session[:id]
      haml :create_organization, :locals => {:action => "create_organization", :button => "create"}
    end

    post "/create_organization" do
      redirect '/index' unless session[:id]
      name = params[:name]
      description = params[:description]
      img_filename = save_image(params[:image_file])
      @session_user.create_organization(name, description, img_filename)
      flash[:notice] = "Organization has been created"
      redirect "/home"
    end

    get '/organizations' do
      redirect '/index' unless session[:id]
      @my_organizations = @session_user.organization_list
      haml :organizations
    end

    get '/logs' do
      redirect '/index' unless session[:id]
      redirect '/index' unless @session_user.working_for.is_a?(Organization)
      @logs = @session_user.working_for.get_activities
      haml :logs
    end

    post "/logs/filter" do
      redirect '/index' unless session[:id]
      filter = Array.new
      unless params[:edit].nil?
        filter.push(params[:edit])
      end
      unless params[:add].nil?
        filter.push(params[:add])
      end
      unless params[:activate].nil?
        filter.push(params[:activate])
      end
      unless params[:deactivate].nil?
        filter.push(params[:deactivate])
      end
      if filter.empty?
        redirect "/logs/filtered/none"
      else
        redirect "/logs/filtered/#{filter}"
      end
    end

    get "/logs/filtered/:filter" do
      redirect '/index' unless session[:id]
      puts(params[:filter])
      # splitting the filter-string, but keeping the split-pattern ("item") and attaching it to the string in front of it
      @logs = @session_user.working_for.get_activities(params[:filter].split(/(item)/).each_slice(2).map(&:join))
      haml :logs
    end

    get '/watching' do
      redirect '/index' unless session[:id]
      haml :watching
    end

    post "/add_user_to_watching_list/:id" do
      redirect '/index' unless session[:id]
      id = params[:id]
      @session_user.working_for.watch(User.get_user(id))
      redirect "/home"
    end

    post "/remove_user_from_watching_list/:id" do
      redirect '/index' unless session[:id]
      id = params[:id]
      @session_user.working_for.unwatch(User.get_user(id))
      redirect "/users/#{id}/1"
    end

    post "/home/filter" do
      redirect '/index' unless session[:id]
      puts(params[:edit])
      puts(params[:add])
      puts(params[:activate])

      filter = Array.new
      unless params[:edit].nil?
        filter.push(params[:edit])
      end
      unless params[:add].nil?
        filter.push(params[:add])
      end
      unless params[:activate].nil?
        filter.push(params[:activate])
      end
      unless params[:deactivate].nil?
        filter.push(params[:deactivate])
      end
      if filter.empty?
        redirect "/home/filtered/none"
      else
        redirect "/home/filtered/#{filter}"
      end

    end

    get "/home/filtered/:filter" do
      redirect '/index' unless session[:id]
      puts(params[:filter])
      # splitting the filter-string, but keeping the split-pattern ("item") and attaching it to the string in front of it
      @activities = @session_user.get_watching_logs(params[:filter].split(/(item)/).each_slice(2).map(&:join))
      haml :home
    end

    def has_errors(user,pw,pw1,check_username_exists)
      validation = catch(:invalid){user.is_valid(pw,pw1,check_username_exists)}
      case validation
        when :invalid_name then
          flash[:error] = "User must have a name\n"
          true
        when :invalid_email then
          flash[:error] = "Invalid e-mail\n"
          true
        when :already_exists then
          flash[:error] = "Username already chosen\n"
          true
        when :no_pw_confirmation then
          flash[:error] = "Password confirmation is required\n"
          true
        when :pw_dont_match then
          flash[:error] = "Passwords do not match\n"
          true
        when :pw_not_safe then
          flash[:error] = "Password is not safe\n"
          true
        when :no_pw then
          flash[:error] = "Password is required"
          true
        when :big_image then
          flash[:error] = "Image is heavier than 400kB"
          true
        else
          false
      end
    end
  end
end