require 'rubygems'
require 'bcrypt'
require 'require_relative'
require 'fileutils'
require_relative('trader')

module Models

  class Organization < Trader
    # [Array]: Members with special rights
    attr_accessor :admin_list
    # [Array]: Users belonging to this organization
    attr_accessor :member_list


    def self.created( name, admin, description = "", image = "")
      org = self.new(name, description, image)
      org.admin_list = []
      org.admin_list.push(admin)
      admin.join_organization(org)
      org.member_list = []
      org.member_list.push(admin)
      org.e_mail = admin.e_mail
      org.organization = true
      org
    end

    def working_for
      self
    end

    # Adds an new admin to the admin_list, containing the members with special rights.
    def add_admin(new_admin)
      unless self.admin_list.include?(new_admin)
        self.admin_list.push(new_admin)
        unless self.member_list.include?(new_admin)
          self.member_list.push(new_admin)
        end
        new_admin.admin_of_org_list.push(self)
      end
    end

    def add_member(new_member)
      unless self.member_list.include?(new_member)
        self.member_list.push(new_member)
        new_member.join_organization(self)
      end
    end

    def delete_admin(admin)
      # ToDo: maybe need to move the check for error-handling
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
  end
end