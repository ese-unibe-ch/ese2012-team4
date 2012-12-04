require 'rubygems'
require 'bcrypt'
require 'require_relative'

module Models


  class PasswordReset

    #a reset-password that is sent to the user
    attr_accessor :reset_password

    #the corresponding user
    attr_accessor :username

    #array containing all the requests
    @@reset_requests = Hash.new

    def self.created(reset_password, username)
      request = self.new
      request.reset_password = reset_password
      request.username = username
      @@reset_requests[username] = reset_password
      request
    end

    # check, if the reset-key is existing
    # - @param reset_link
    def self.request_exists_for_user?(username)
      @@reset_requests.has_key? username
    end

    def self.request_exists_for_id?(reset_pw, salt)
      reset_pw_check = BCrypt::Engine.hash_secret(reset_pw, salt)
      @@reset_requests.invert.has_key? reset_pw_check
    end

    def self.getValue(username)
      @@reset_requests[username]
    end

    def self.getKey(reset_pw)
      @@reset_requests.invert[reset_pw]
    end

    def self.generate_random_pw
      map = [('a'..'z'),('A'..'Z'),(1..9)].map{|i| i.to_a}.flatten
      new_password  =  (0...50).map{ map[rand(map.length)] }.join
    end

  end

end