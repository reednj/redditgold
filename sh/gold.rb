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

		insert_comments comments
	end

	def reddit_data
		data = RestClient.get 'http://www.reddit.com/r/all/comments/gilded.json?count=50'
		return JSON.parse(data, :symbolize_names => true)
	end

	def remove_duplicates(response)
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
		#foreach(array_reverse($new_comments) as $comment) {
		#	
		#	print  $comment->data->id . "\n";
		#
		#	if(is_thread($comment->data->name)) {
		#		$thread_id = $comment->data->name;
		#		$title = $comment->data->title;
		#		$body = $comment->data->is_self == 1 ? $comment->data->selftext : '';
		#	} else {
		#		$thread_id = $comment->data->link_id;
		#		$title = $comment->data->link_title;
		#		$body = $comment->data->body;
		#	}
		#
		#	Comments::Insert(array(
		#		'comment_id' => $comment->data->id,
		#		'thread_id' => $thread_id,
		#		'user' => $comment->data->author,
		#		'subreddit' => $comment->data->subreddit,
		#		'gold_count' => $comment->data->gilded,
		#		'post_date' => date('c', $comment->data->created_utc)
		#	));
		#	
		#	ESQL::Insert('comment_content', array(
		#		'comment_id' => $comment->data->id,
		#		'content' => $body,
		#		'title' => $title
		#	));

		comments.each do |comment|
			puts "#{comment[:data][:id]} (is_thread: #{thread? comment})"
		end

	end

	def thread?(comment)
		comment[:data][:name].start_with? 't3_'
	end

	def last_comment_id
		@db.db[:comments].reverse_order(:gold_id).get :comment_id
	end
end

App.new.main
