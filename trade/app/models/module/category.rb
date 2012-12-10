module Models

  require 'require_relative'
  require_relative('offer')

  # Represents a category of different offers in the system.
  # A category contains several subcategories. A category can return offers belonging to this category
  # This class is not constructed to go deeper than three levels, that means:
  # - First level: The constructed supercategory, that you can receive by invoking the get_supercategory method
  # - Second level: Subcategories of the supercategory
  # - Third level: Subcategories of the above mentioned subcategories of the supercategory
  class Category
    # [String]: The name of this category. Is used to identify a category as well, do not create two categories with the same name
    attr_accessor :name
    @subcategories

    def initialize(name)
      self.name = name
      @subcategories = Array.new
    end

    def get_subcategories
      @subcategories
    end

    def to_s
      self.name
    end

    # Adds a new category to the subcategories, if it is not yet belonging to them.
    def add(category)
      if !@subcategories.include?(category) and !self.get_names.include?(category.name)
        @subcategories.push(category)
      end
    end

    def remove(category)
      @subcategories.delete(category)
    end

    # - @return [Array]: The offers belonging to this category, or to one of its subcategories.
    def get_offers(viewer = nil, options ={})
      ret_array = Array.new
      for offer in Offer.get_all(viewer, options)
        if offer.category.name == self.name
          ret_array.push(offer)
        end
      end
      for cat in @subcategories
        ret_array.concat(cat.get_offers)
      end
      ret_array
    end

    # - @return [Array]: The names of the subcategories of this category
    def get_names
      ret_array = Array.new
      for subcat in @subcategories
        ret_array.push(subcat.name)
      end
      ret_array
    end

    # Searches for a category with the given name in all subcategories of the supercategory.
    # Doesn't search deeper than two levels (in subcategories of subcategories of the supercategory)
    # - @return [Category]: The category with the given name
    def self.by_name(name)
      ret_category = nil
      if name == @@supercategory.name
        ret_category = @@supercategory
      else
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
      end
      ret_category
    end

    def self.delete_all
      @@supercategory = self.new("No Category")
    end

    def self.get_supercategory
      @@supercategory
    end
    @@supercategory = self.new("No Category")
  end
end