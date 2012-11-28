require 'rubygems'
require 'date'

class Activity
  attr_accessor :author, :topic, :subject, :time, :target

  def self.log(author, topic, subject, target)
    activity = Activity.create(author, topic, subject, target)
    activity.attach
  end

  def self.create(author, topic, subject, target = nil)
    activity = self.new
    activity.author = author
    activity.topic = topic
    activity.subject = subject
    activity.time = DateTime.now
    activity.target = target
    activity
  end

  def attach
    self.target.activities.push(self)
  end

  def to_s
    text = case self.topic
             when "add_item" then "#{self.author.name} added '#{self.subject.name}' for a price of #{self.subject.price} credits"
             when "bid" then "#{self.author.name} placed a bid for #{self.subject.name}"
             when "edit_item" then "#{self.author.name} edited '#{self.subject.name}'"
             when "activate_item" then "#{self.author.name} activated '#{self.subject.name}'"
             when "deactivate_item" then "#{self.author.name} deactivated '#{self.subject.name}'"
             when "comment_item" then "#{self.author.name} commented on '#{self.subject.name}'"
             when "item_sold_success" then "'#{self.subject.name}' was bought by #{self.author.name} for #{self.subject.price} credits"
             when "item_sold_failure" then "'#{self.subject.name}' could not be bought by #{self.author.name} for #{self.subject.price} credits"
             when "item_bought_success" then "#{self.author.name} has bought '#{self.subject.name}' for #{self.subject.price} credits"
             when "item_bought_failure" then "#{self.author.name} was unable to buy '#{self.subject.name}' for #{self.subject.price} credits"

    end
  end

  def to_html
    user_link = "<a href='/users/#{self.author.id}'>#{self.author.name}</a>"
    item_link = "<a href='/item/#{self.subject.id}'>#{self.subject.name}</a>"
    comment_link = "<a href='/comments/#{self.subject.id}'>#{self.subject.name}</a>"
    item_price = self.subject.price
    text = case self.topic
             when "add_item" then "#{user_link} added '#{item_link}' for a price of #{item_price} credits"
             when "bid" then "#{user_link} placed a bid for #{item_link}"
             when "edit_item" then "#{user_link} edited '#{item_link}'"
             when "activate_item" then "#{user_link} activated '#{item_link}'"
             when "deactivate_item" then "#{user_link} deactivated '#{item_link}'"
             when "comment_item" then "#{user_link} commented on '#{item_link}'"
             when "item_sold_success" then "'#{item_link}' was bought by #{user_link} for #{item_price} credits"
             when "item_sold_failure" then "'#{item_link}' could not be bought by #{user_link} for #{item_price} credits"
             when "item_bought_success" then "#{user_link} has bought '#{item_link}' for #{item_price} credits"
             when "item_bought_failure" then "#{user_link} was unable to buy '#{item_link}' for #{item_price} credits"

           end
  end
end