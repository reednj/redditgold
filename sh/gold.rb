#!/usr/bin/ruby

require 'sequel'
require 'yaml'
require 'json'
require 'rest-client'

require '../config/db.rb'
require '../lib/simpledb'

class App

	def initialize
		@db = SimpleDb.new
	end

	def main
		response = reddit_data
		comments = response[:data][:children]
		process_comments comments.reverse
	end

	def reddit_data
		data = RestClient.get 'http://www.reddit.com/r/all/comments/gilded.json?count=50'
		return JSON.parse(data, :symbolize_names => true)
	end

	def process_comments(comments)

		comments.each do |comment|
			comment_id = comment[:data][:id]
			gold = last_gold_for_comment(comment_id)

			if gold.nil?
				insert_comment comment
				insert_comment_content comment
				puts "#{comment_id} - new"
			elsif gold[:gold_count] < comment[:data][:gilded]
				insert_comment comment
				puts "#{comment_id} - updated inserted"
			else
				puts "#{comment_id} - no change"
			end

		end

	end

	def insert_comment(comment)
		data = comment[:data]
		thread_id = thread?(comment) ? data[:name] : data[:link_id]

		@db.db[:comments].insert({
			:comment_id => data[:id],
			:thread_id => thread_id,
			:user => data[:author],
			:subreddit => data[:subreddit],
			:gold_count => data[:gilded],
			:post_date => Time.at(data[:created_utc]),
		})

	end

	def insert_comment_content(comment)
		data = comment[:data]

		if thread? comment
			title = data[:title]
			body = data[:is_self] == 1 ? data[:selftext] : ''
		else
			title = data[:link_title]
			body = data[:body]
		end

		if !has_content? comment
			
			@db.db[:comment_content].insert({
				:comment_id => data[:id],
				:content => body,
				:title => title
			})
		end
	end

	def thread?(comment)
		comment[:data][:name].start_with? 't3_'
	end

	def has_content?(comment)
		!@db.db[:comment_content].where(:comment_id => comment[:data][:id]).first.nil?
	end

	def last_gold_for_comment(comment_id)
		@db.db[:comments].where(:comment_id => comment_id).reverse_order(:gold_id).first
	end
end

App.new.main
