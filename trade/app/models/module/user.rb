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
      throw :invalid, :invalid_name unless self.name.strip.delete(' ')!=""
      throw :invalid, :invalid_email if self.e_mail=='' || self.e_mail.count("@")!=1 || self.e_mail.count(".")==0
      throw :invalid, :already_exists unless (User.available? self.name) || !check_username_exists

      if pw != nil || pw2 != nil
        if pw != nil || pw != ""
          if pw2 == nil || pw2 == ""
            throw :invalid, :no_pw_confirmation
          else
            throw :invalid, :pw_dont_match unless pw == pw2
            throw :invalid, :pw_not_safe unless PasswordCheck.safe?(pw)
          end
        else
          throw :invalid, :no_pw
        end
      end
      if image != ""
        dim = Dimensions.dimensions(image)
        unless image.size <= 400*1024
          FileUtils.rm(image, :force => true)
          throw :invalid, :big_image
        end
      end
      true
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

    # Generates a password-reset-link
    def forgot_password()
      new_password = PasswordReset.generate_random_pw
      new_password_crypt = BCrypt::Engine.hash_secret(new_password, password_salt)
      new_request = PasswordReset.created(new_password_crypt, self.name.strip.downcase)
      new_password
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