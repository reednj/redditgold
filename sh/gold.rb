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
		comments = remove_duplicates response

		insert_comments comments.reverse
	end

	def reddit_data
		data = RestClient.get 'http://www.reddit.com/r/all/comments/gilded.json?count=50'
		return JSON.parse(data, :symbolize_names => true)
	end

	def remove_duplicates(response)
		last_id = last_comment_id

		#foreach($data->data->children as $comment) {
		#	if($comment->data->id == $last_comment) {
		#		break;
		#	}
		#
		#	array_push($new_comments, $comment);
		#}

		response[:data][:children]
	end

	def insert_comments(comments)

		comments.each do |comment|
			insert_comment comment
			puts "#{comment[:data][:id]}"
		end

	end

	def insert_comment(comment)
			data = comment[:data]

			if thread? comment
				thread_id = data[:name]
				title = data[:title]
				body = data[:is_self] == 1 ? data[:selftext] : ''
			else
				thread_id = data[:link_id]
				title = data[:link_title]
				body = data[:body]
			end

			@db.db[:comments].insert({
				:comment_id => data[:id],
				:thread_id => thread_id,
				:user => data[:author],
				:subreddit => data[:subreddit],
				:gold_count => data[:gilded],
				:post_date => Time.at(data[:created_utc]),
			})

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

	def last_comment_id
		@db.db[:comments].reverse_order(:gold_id).get :comment_id
	end
end

App.new.main
