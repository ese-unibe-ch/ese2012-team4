require 'rubygems'
require 'bcrypt'
require 'require_relative'
require 'fileutils'
require_relative('../utility/password_check')
require_relative('../utility/password_reset')
require_relative('trader')


# ToDo: move some of these requires to trader


module Models

  # Represents a user in the System. A user can trade items, therefore it extends Trader
  # A user does have a password and an e_mail address
  class User < Trader

    # Save storage of the users password
    attr_accessor :password_hash
    # Save storage of the users password
    attr_accessor :password_salt
    # [String]
    attr_accessor :e_mail
    # List of organization this user is part of
    attr_accessor :organization_list
    # List of organization this user is admin of
    attr_accessor :admin_of_org_list

    attr_accessor :working_for

    # factory method (constructor) on the class
    def self.created( name, password, e_mail, description = "", image = "")
      user = self.new(name, description, image)
      user.e_mail = e_mail
      pw_salt = BCrypt::Engine.generate_salt
      pw_hash = BCrypt::Engine.hash_secret(password, pw_salt)
      user.password_salt = pw_salt
      user.password_hash = pw_hash
      user.organization_list = []
      user.admin_of_org_list = []
      user.working_for = user
      user
    end

    # Creates a copy of an instance, while replacing the instance variables defined in the parameter hash
    # usage: user1.copy(:name => "User 2")
    def copy( hash = {} )
      User.created(hash[:name] || self.name, "FdZ.(gJa)s'dFjKdaDGS+J1",
                           hash[:e_mail] || self.e_mail,
                           hash[:description] || self.description)
    end


    # Checks whether a combination of an username, a password and a confirmation is valid or not.
    # - @param [String] pw: a password.
    # - @param [String] pw2: the confirmation of the password.
    # - @param [boolean] check_username_exists: whether the username is already taken or not
    def is_valid(pw = nil, pw2 = nil, check_username_exists = true)
      self.errors = ""
      self.errors += "User must have a name\n" unless self.name.strip.delete(' ')!=""
      self.errors += "Invalid e-mail\n" if self.e_mail=='' || self.e_mail.count("@")!=1 || self.e_mail.count(".")==0
      self.errors += "Username already chosen\n" unless (User.available? self.name) || !check_username_exists
      if pw != nil || pw2 != nil
        if pw != nil || pw != ""
          if pw2 == nil || pw2 == ""
            self.errors += "Password confirmation is required\n"
          else
            self.errors += "Passwords do not match\n" unless pw == pw2
            self.errors += "Password is not safe\n" unless PasswordCheck.safe?(pw)
          end
        else
          self.errors += "Password is required"
        end
      end
      if image != ""
        self.errors += "Image is heavier than 400kB" unless image.size <= 400*1024
        dim = Dimensions.dimensions(image)
  #      self.errors += "Image is no square" unless dim[0] == dim[1]
  #      unless image.size <= 400*1024 && dim[0] == dim[1]
        unless image.size <= 400*1024
          FileUtils.rm(image, :force => true)
        end
      end
      self.errors != "" ? false : true
    end

    def change_password(password)
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = BCrypt::Engine.hash_secret(password, self.password_salt)
    end

    # Compares a string to the password of an user
    # - @param [String] password: The password due for comparison
    # - @return [boolean]: true if equal, false otherwise
    def check_password(password)
      self.password_hash == BCrypt::Engine.hash_secret(password, self.password_salt)
    end

    def forgot_password()
      #generate new random password out of letters
      new_password = PasswordReset.generate_random_pw
      new_request = PasswordReset.created(new_password, self.name)

      #self.change_password(new_password)
      Mailer.reset_pw(self.e_mail, "Hi #{self.name}, \n
        You forgot your password, you can reset your password with the following link: \n
        http://localhost:4567/pwreset/#{new_password} \n")
    end

    # Adds an organization to the user's organization list
    def join_organization(organization)
      self.organization_list.push(organization) unless self.organization_list.include?(organization)
    end


    #get string representation
    def to_s
      "#{self.name} has currently #{self.credits} credits, #{list_items.size} active and #{list_items_inactive.size} inactive items"
    end

    def self.login(id, password)
      user = @@traders[id]
      return false if user.nil?
      user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
    end

    # - @return [User]: the user with the given user_id
    # ToDo: maybe we need to adapt this, if we want to list organizations and users differently...
    def self.get_user(user_id)
      return @@traders[user_id.to_i]
    end



    def create_organization(name, description = "", image = "")
      new_organization = Organization.created(name, self, description, image)
      new_organization.save
      #self.organization_list.push(new_organization)
    end
  end
end