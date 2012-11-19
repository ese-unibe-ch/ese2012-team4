
module Models

  class Organization < Trader

    def self.created( name, description = "", image = "")
      org = self.new(name, description, image)

    end

    # ToDo: organizations with admin, list of users, e_mail? (or store admin-e_mail)
  end
end