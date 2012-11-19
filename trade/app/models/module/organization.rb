require 'rubygems'
require 'bcrypt'
require 'require_relative'
require 'fileutils'
require_relative('trader')

module Models

  class Organization < Trader
    attr_accessor :admin_list
    attr_accessor :member_list
    attr_accessor :e_mail

    def self.created( name, admin, description = "", image = "")
      org = self.new(name, description, image)
      org.admin_list = []
      org.admin_list.push(admin)
      org.member_list = []
      org.member_list.push(admin)
      org.e_mail = admin.e_mail
      org
    end

    # ToDo: organizations with admin, list of users, e_mail? (or store admin-e_mail)
  end
end