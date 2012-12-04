module Models

  require 'require_relative'
  require_relative('offer')

  # Represents a category of different offers
  # A category contains several components, a component is either a new category or an object providing a list method.
  # A known class providing this is Offer
  class Category

    attr_accessor :name
    @components

    def initialize(name)
      self.name = name
      @components = Array.new
    end

    def get_subcategories
      @components
    end

    def to_s
      self.name
    end

    def add(component)
      @components.push(component)
    end

    def remove(component)
      @components.delete(component)
    end

    def get_offers(viewer = nil, options ={})
      ret_array = Array.new
      for offer in Offer.get_item_list
        if offer[1].category.name == self.name
          ret_array.push(offer[1])
        end
      end
      ret_array
    end

    # Searches for a category with the given name in all subcategories of the supercategory.
    # Doesn't search deeper than two levels (in subcategories of subcategories of the supercategory)
    # - @return [Category]: The category with the given name
    def self.by_name(name)
      ret_category = nil
      for cat in @@supercategory.get_subcategories
        if cat.name == name
          ret_category = cat
        else
          #check subcategories
          for subcat in cat.get_subcategories
            if subcat.name == name
              ret_category = subcat
            end
          end
        end
      end
      ret_category
    end

    def self.get_supercategory
      @@supercategory
    end
    @@supercategory = self.new("No Category")
  end
end