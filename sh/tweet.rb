#!/usr/bin/ruby

require 'sequel'
require 'yaml'
require 'json'
require 'twitter'

require_relative '../lib/model'
require_relative '../lib/twitter-config'

class App

	def main
		@twitter_user = 'reddit_stream'
		comment = first_untweeted_comment

		if comment.nil?
			puts 'nothing to tweet'
			return
		end

		# tweet the thread / comment, and print it to the 
		# console
		tweet_content = comment.to_tweet
		puts tweet_content
		twitter_client.update tweet_content 
		
		
		# now mark the comment as tweeted so we won't send it out again
		comment.was_tweeted = 1
		comment.save_changes
	end

	def first_untweeted_comment
		comment_ids = SDB.top_comments(7).first(5).map{|c| c[:comment_id] }
		comments = CommentContent.where(:comment_id => comment_ids).all
		comments.select {|c| !c.tweeted? }.first
	end

	def twitter_client
		config_file = '../config/twitter.yaml'
		@twitter_client ||= Twitter::REST::Client.from_config(@twitter_user, :path => config_file)
	end


end


App.new.main

