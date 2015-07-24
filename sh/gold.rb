#!/usr/bin/ruby

ENV['GEM_PATH'] = File.expand_path('~/.gems') + ':/usr/lib/ruby/gems/1.8'
require 'rubygems'

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
		# get the latest records, and add them to the database
		response = reddit_data
		comments = response[:data][:children]
		process_comments comments.reverse

		# in order to run queries on the data over bigger time peroids
		# we need to summarize things. This method will summarize the
		# current day every 6 hours, and summarize a few historical days
		# as well (so eventually everything will be there, without having
		# to runna massive query)
		Summarizer.new(@db.db).run_summarization
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
				gold_change = comment[:data][:gilded] - gold[:gold_count]
				insert_comment comment, gold_change
				puts "#{comment_id} - updated inserted"
			else
				puts "#{comment_id} - no change"
			end

		end

	end

	def insert_comment(comment, gold_change=nil)
		data = comment[:data]
		thread_id = thread?(comment) ? data[:name] : data[:link_id]
		
		# in order to make summarizing the data easier, we don't just want the total
		# gold that a comment has, we want to get the change since the last entry as well
		# this will let us calculate $/month with less fucking around
		gold_change ||= data[:gilded]

		@db.db[:comments].insert({
			:comment_id => data[:id],
			:thread_id => thread_id,
			:user => data[:author],
			:subreddit => data[:subreddit],
			:gold_count => data[:gilded],
			:gold_change => gold_change,
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

# in order to get stats over a time period longer than about a week, then we need to summarize
# the daily figures
class Summarizer
	def initialize(db)
		@db = db
	end

	def run_summarization
		last = self.last_summary
		if last.nil? || last.age > 6.hours
			self.summarize_range Date.today - 1, Date.today
			puts 'current date summarized'
		end

		self.summarize_historical
	end

	# summarize at most max_days, from the current oldest date, until we
	# eventually reach the data_start_date. If the oldest date is before that
	# then do nothing - we have summarized everything
	def summarize_historical(max_days = 5)
		data_start_date = self.oldest_comment.to_date
		current_oldest = self.oldest_summary
		return if current_oldest <= data_start_date

		start_date = current_oldest - max_days
		end_date = current_oldest - 1
		self.summarize_range(start_date, end_date)

		puts 'historical summary records added'
	end

	def summarize_range(start_date, end_date)
		(start_date..end_date).each do |date|
			self.summarize_day date
		end
	end

	def summarize_day(date)
		date = date.to_date if date.respond_to? :to_date
		raise 'needs a date' unless date.kind_of? Date

		data = gold_for_day date

		self.clear_summary(date)
		self.insert_summary(date, data[:gold_count], data[:comment_count])
	end

	# date of the last summary, when this gets to a certain age, then we run the summary again
	# - we don't want to have to have a separate cron job for it
	def last_summary
		@db[:gold_summary].reverse_order(:created_date).get(:created_date)
	end

	# we want to get the oldest summary as well so that we can slowly fill 
	# in the historical data
	def oldest_summary
		@db[:gold_summary].order_by(:summary_date).get(:summary_date) || Date.today
	end

	def oldest_comment
		@db[:comments].order_by(:created_date).get(:created_date) || Date.today
	end

	def gold_for_day(date)
		dataset = @db[:comments].where('date(created_date) = ?', date)
		gold_count = dataset.count
		comment_count = dataset.distinct(:comment_id).count
		return { :gold_count => gold_count, :comment_count => comment_count }
	end

	def clear_summary(date)
		@db[:gold_summary].where(:summary_date => date).delete
	end

	def insert_summary(date, gold_count, comment_count)
		gold_cost = 3.99
		@db[:gold_summary].insert(
			:summary_date => date,
			:gold_count => gold_count,
			:comment_count => comment_count,
			:gold_profit => (gold_count * gold_cost)
		)
	end
end

class Time
	def to_date
		::Date.new(year, month, day)
	end
end

App.new.main
