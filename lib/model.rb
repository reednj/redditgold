require_relative '../config/db'
require_relative './simpledb'
require_relative './sequel-notes_tables'

SDB = SimpleDb.new 
DB = SDB.connect

class Comment < Sequel::Model
	many_to_one :content, :class => 'CommentContent', :key => :comment_id
end

class CommentContent < Sequel::Model(:comment_content)
	one_to_many :comments, :key => :comment_id, :order_by => :post_date

	include NotesTableHelpers
	create_notes_table? :name => :comment_notes
	add_notes_assoc 'CommentNote'
	add_notes_field :was_tweeted

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
		suffix = " #reddit"
		text_len = tweet_len - link_len - prefix.length - suffix.length
		raise 'no room for tweet content' if text_len <= 0

		return "#{prefix}#{plain_text.truncate(text_len, "\u2026")} #{link_to}#{suffix}"
	end

	def tweeted?
		was_tweeted.to_i == 1
	end
end

class CommentNote < Sequel::Model
end
