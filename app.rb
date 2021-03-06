
require 'sinatra'
require "sinatra/content_for"
require "sinatra/reloader" if development?
require 'sequel'
require 'json'
require 'yaml'
require 'erubis'

require './config/db'
require './lib/model'
require './lib/filecache'

set :gitdir, development? ? './.git' : '/home/reednj/code/redditgold.git/.git'
set :version, GitVersion.current(settings.gitdir)
set :erb, :escape_html => true

GOLDCOST = 3.99
DB = SimpleDb.new

# by default all the errors in RACK get dumped to stderr - we want to 
# change this so that it goes to a file, so we can capture the output
# on systems where we don't have control over stderr
def map_error_output(filename)
	Dir.mkdir("#{settings.root}/tmp") unless File.exists?("#{settings.root}/tmp")
	file = File.new("#{settings.root}/tmp/#{filename}", 'a+')
	file.sync = true
	$stderr.reopen file
end

configure :development do
	# set :raise_errors, false
	# set :show_exceptions, false

	# run the db backup script to make sure the schema we have stored is up to date...
	`./config/db/export-db.sh` if !Gem.win_platform?

	also_reload './lib/simpledb.rb'
	also_reload './lib/filecache.rb'
end

configure :production do
	map_error_output("#{settings.environment}.log")
end

configure do

	# we have a table with a list of dates we can join against to do reporting and so on.
	# this should be populated the first time we start the app
	if !DB.date_list_exist?
		puts 'populating the date list. This might take a few minutes...'
		DB.populate_dates
	end
	
end

get '/error/test' do
	raise 'test error'
end

get '/' do
	
	fc = FileCache.new
	gold_cost = GOLDCOST

	locals = fc.cache('gold.data', 5.minutes) do
		data = {
			:day_count => DB.gold_count(1) * gold_cost,
			:week_count => DB.gold_count(7) * gold_cost,
			:month_count => DB.gold_count(30) * gold_cost,
			:daily_data => DB.revenue_by_day(30),
			:top_comments => DB.top_comments(7)[0..5],
			:data_age => DB.last_comment_age
		}

		data = data.merge({ 
			:day_rate => data[:day_count] / (1 * 24),
			:week_rate => data[:week_count] / (7 * 24),
			:month_rate => data[:month_count] / (30 * 24)
		})

		puts 'Cache Refresh'
		data
	end

	erb :index, :layout => :_layout, :locals => locals
end

get '/r/:subreddit' do |subreddit|

	start_date = DB.subreddit_start(subreddit)
	halt 404, 'subreddit not found' if start_date.nil?

	locals = FileCache.new.cache "#{subreddit}.data.txt", 5.minutes do
		{
			:subreddit => subreddit,
			:count_data => DB.subreddit_revenue(subreddit),		
		}
	end

	locals[:start_date] = start_date
	erb :subreddit, :layout => :_layout, :locals => locals
end

get '/gold/table' do

	FileCache.new.cache('table.data.txt', 5.minutes, :plain_text => true) do  
		erb :table, :layout => :_layout, :locals => {
			:weekly_data => DB.revenue_by_week(12.weeks.ago),
			:monthly_data => DB.revenue_by_month(52.weeks.ago),
			:yearly_data => DB.revenue_by_year
		}
	end

end


get '/gold/this_month' do
	data = DB.revenue_since Time.now.beginning_of_month
	return [200, {'Content-type' => 'text/plain'}, data.to_s]
end

get '/status/age' do
	comment = Comment.last
	is_age_ok = comment.created_date.age < 1.hour
	http_status = is_age_ok ? 200 : 500

	return [
		http_status, 
		{"Content-Type" => 'application/json'}, 
		{
			:status => is_age_ok ? 'ok' : 'too_old',
			:age => comment.created_date.age.to_i,
			:age_text => comment.created_date.age_in_words
		}.to_json
	]
end
