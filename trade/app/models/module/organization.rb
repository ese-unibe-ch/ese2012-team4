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
      admin.join_organization(org)
      org.member_list = []
      org.member_list.push(admin)
      org.e_mail = admin.e_mail
      org
    end




    def add_admin(new_admin)
      self.admin_list.push(new_admin)
      new_admin.admin_of_org_list.push(self)
    end

    def add_member(new_member)
      self.member_list.push(new_member)
      new_member.organization_list.push(self)
    end

    #maybe need to move the check for error-handling
    def delete_admin(admin)
      if can_delete_admin?
        self.admin_list.delete(admin)
        admin.admin_of_org_list.delete(self)
      end
    end

    def can_delete_admin?
      self.admin_list.length > 1
    end

    def delete_member(member)
      self.member_list.delete(member)
      member.organization_list.delete(self)
    end

    # ToDo: organizations with admin, list of users, e_mail? (or store admin-e_mail)
  end
end