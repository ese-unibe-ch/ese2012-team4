module Models

  # Represents a category of different offers
  # A category contains several components, a component is either a new category or an object providing a list method.
  # A known class providing this is Offer
  class Category

    attr_accessor :name
    @components = []
    @@supercategory = self.new("all")

    def initialize(name)
      self.name = name
    end
    def list
      ret_array = Array.new
      for e in @components
        ret_array.push(e.list)
      end
    end

    def add(component)
      @components.push(component)
    end

    def remove(component)
      #ToDo: removing components
    end

    def self.get_supercategory
      @@supercategory
    end
  end
end