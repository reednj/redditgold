#!/usr/bin/ruby

require 'sequel'
require 'yaml'
require 'json'
require 'twitter'

require '../config/db'
require '../lib/simpledb'
require '../lib/sequel-notes_tables'

SDB = SimpleDb.new 
DB = SDB.connect

DB.create_table? :comment_notes do 
	String :comment_id, :size => 64
	String :field_name, :size => 32
	String :field_value, :size => 64
	primary_key [:comment_id, :field_name]
end

class CommentNote < Sequel::Model
end

class Comment < Sequel::Model
	many_to_one :content, :class => 'CommentContent', :key => :comment_id
end

class CommentContent < Sequel::Model(:comment_content)
	one_to_many :comments, :key => :comment_id, :order_by => :post_date

	extend NotesTableHelpers
	add_notes_assoc 'CommentNote'
	add_notes_field :was_tweeted

	def self.notes_class
		CommentNote
	end

	def gold_count
		@gold_count ||= comments_dataset.max(:gold_count)
	end

	def subreddit
		comments.last.subreddit
	end

	def username
		comments.last.user
	end

	def thread_id
		 full_thread_id.gsub('t3_', '')
	end

	def full_thread_id
		comments.last.thread_id
	end

	def link_to
		return "http://www.reddit.com/comments/#{thread_id}" if thread?
		"http://www.reddit.com/comments/#{thread_id}/-/#{comment_id}"
	end

	# was this gold given to a thread? (instead of a comment on the thread)
	def thread?
		thread_id == comment_id
	end

	# if this is a thread, then does it consist of just a link somewhere else,
	# or is a self post consisting of only text
	def self_thread?
		thread? && has_content?
	end

	def has_content?
		!content.nil? && !content.empty?
	end

	def text
		has_content? ? content : title
	end

	# this tries to remove all formatting etc from the text so it fits nicely
	# into a tweet ro whatever
	def plain_text
		text.gsub("\n", ' ').gsub("\t", ' ').gsub('  ', ' ')
	end

	def to_tweet
		tweet_len = 140
		link_len = 25

		prefix = "#{gold_count}\u2605 [/r/#{subreddit}] "
		suffix = " #redditgold"
		text_len = tweet_len - link_len - prefix.length - suffix.length
		raise 'no room for tweet content' if text_len <= 0

		return "#{prefix}#{plain_text.truncate(text_len, "\u2026")} #{link_to}#{suffix}"
	end

	def tweeted?
		was_tweeted.to_i == 1
	end
end

class App

	def main
		client = Twitter::REST::Client.new twitter_config('reednj', :path => '../config/twitter.yaml')
		comment_ids = SDB.top_comments(7).first(5).map{|c| c[:comment_id] }
		comment_ids.each do |id|
			c = CommentContent[id]
			puts c.to_tweet
		end

		client.update CommentContent[comment_ids.first].to_tweet
	end

	def first_comment

	end

	def twitter_config(username, options = {})
		path = twitter_config_file options[:path]
		config_data = YAML.load_file path
		user_config = config_data[username]
		raise "no config found for #{username} in file #{path}" if user_config.nil?

		return user_config
	end

	def twitter_config_file(path = nil)
		result = [path, '~/.twitter.yaml', './twitter.yaml'].compact.select{ |f| File.exist? f }.first
		raise 'could not find twitter config' if result.nil?
		return result
	end
end


App.new.main
