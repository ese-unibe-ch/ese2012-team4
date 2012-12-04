module Models

  require 'dimensions'
  require 'require_relative'
  require_relative('comment')
  require_relative('offer')


  # Represents an item in the shop, stores its data and different states.
  # The class stores all created items in a list.
  class Item < Offer
    # [Integer]: The price in credits
    attr_accessor :price
    # [Boolean]: True, if the item can be bought
    attr_accessor :active

    attr_accessor :permanent
    @comment_count = 0


    # Factory method (constructor) on the class.
    # - @param [String] name
    # - @param [Integer] price
    # - @param [User] owner
    # - @param [Integer] quantity
    # - @param [String] description
    # - @param [String] image: The Path of the Image to be displayed.
    # - @return [Item] The created Item.
    def self.created( name, price, owner, quantity, description = "", image = "")
      item = self.new
      item.price = price
      item.active = false

      item.id = @@count + 1
      item.name = name
      item.owner = owner
      item.quantity = quantity
      item.description = description
      item.image = image
      item.wishlist_users = Array.new
      item.timestamp = Time.now.to_i
      item.head_comments = []
      item.auction = false
      item.permanent = false
      item
    end

    # Creates a copy of an instance, while replacing the
    # instance variables defined in the parameter hash
    # usage: my_item.copy(:name => "Item2")
    # - @param [Hash] hash: Hash, containing:
    #   - [String] :name
    #   - [Integer] :price
    #   - [User] :owner
    #   - [Integer]:quantity
    #   - [String] :description
    # - @return [Item]: A copy of this Item with the new variables.
    def copy( hash = {})
      item = Models::Item.created(hash[:name] || self.name, hash[:price] || self.price,
                                  hash[:owner] || self.owner, hash[:quantity] ||self.quantity,
                                  hash[:description] || self.description, hash[:image] || self.image)
      item
    end

    # Controls the item's data and adds errors if necessary.
    # - @return: true if there is no invalid data and throws a suitable symbol otherwise.
    def is_valid
      throw :invalid, :invalid_name unless self.name.strip.delete(' ')!=""
      throw :invalid, :invalid_price unless Item.valid_integer?(self.price)
      throw :invalid, :invalid_quantity unless Item.valid_integer?(self.quantity)

      if image != ""
        throw :invalid, :big_image unless image.size <= 400*1024
        begin
          dim = Dimensions.dimensions(image)
          unless image.size <= 400*1024
            FileUtils.rm(image, :force => true)
          end
        rescue Errno::ENOENT
          throw :invalid, :no_valid_image_file
        end
      end
      true
    end


    # Replaces the data of this Item with the given params.
    # - @param [String] name
    # - @param [Integer] price
    # - @param [Integer] quantity
    # - @param [String] description
    # - @param [String] image
    def edit(name, price, quantity,  description = "", image = "")
      return false if self.active
      self.name = name
      self.price = price
      self.description = description
      if image != ""
        FileUtils.rm(self.image, :force => true)
        self.image = image
      end
      self.quantity = quantity
      self.timestamp = Time.now.to_i
    end

    # Get the activation state.
    # Use this method instead of .active if you want to update the state if the item is expired.
    def is_active?
      self.active
    end

    # Checks if a string is a valid price.
    # - @param [String] price_string: The String that should be tested.
    def self.valid_integer?(price_string)
      (!!(price_string =~ /^[-+]?[1-9]([0-9]*)?$/) && Integer(price_string) >= 0 || (price_string.is_a? Integer))
    end

    # Overrides to String method of Object.
    def to_s
      "#{self.name}, #{self.price}"
    end

    def editable?
      !self.active
    end

    # changes whether the item is permanent or not
    def switch_permanent
      self.permanent = self.permanent ? false : true
    end

    # adds quantity to an item with permanent stock
    def restock (amount)
      return false unless self.permanent
      self.quantity += amount.to_i
    end

    def delete
      self.owner.remove_offer(self)
      @@offers.delete(self)
    end

    # Adds a new Comment on this Item.
    # -@param [User] author: The User who wrote the Comment.
    # -@param [String] text: The text of the Comment.
    # -@return [Comment]: The created Comment.
    def comment (author, text)
      c = Models::Comment.created(author, self, text)
      c.save
      head_comments[Integer(@comment_count)] = c
      @comment_count = Integer(@comment_count) + 1
      c
    end

    # - @param [String] search_string: Keywords for whom should be searched. Keywords must be separated by spaces.
    # - @param [User] user: The user requesting the item list.
    # - @return [Array]: Items whose names or descriptions contain a the keywords and are visible to the given user.
    def self.search (search_string, user, options = {})
      o = {
          :order_by => 'name',
          :order_direction => 'asc'
      }.merge(options)

      s_array = search_string.downcase.split
      ret_array = []
      i_array = @@offers.to_a

      provisional = i_array.select do |item|
        unless item[1].nil?
          s_array.all?{|keyword| (item[1].name.downcase+" "+item[1].description.downcase).include? keyword.downcase}
        end
      end
      for item in provisional
        i = item[1]
        if i.is_active? or i.owner==user
          ret_array.push(i)
        end
      end
      if o[:order_direction] == 'asc'
        return ret_array.sort{ |a,b| a.send(o[:order_by]) <=> b.send(o[:order_by]) }
      else
        return ret_array.sort{ |a,b| b.send(o[:order_by]) <=> a.send(o[:order_by]) }
      end
    end

    def self.clear_all
      @@offers = {}
    end

    def add_user_to_wishlist(user)
      wishlist_users.push(user)
    end

    def remove_user_from_wishlist(user)
      wishlist_users.delete(user)
    end

    def activate
      self.active = true
    end

    def deactivate
      self.active = false
    end

    def seller_rating
      self.owner.rating
    end
  end
end