
require 'sinatra'
require "sinatra/content_for"
require "sinatra/reloader" if development?
require 'sequel'
require 'json'
require 'erubis'

require './config/db'
require './lib/simpledb'
require './lib/filecache'

set :gitdir, development? ? './.git' : '/home/reednj/code/redditgold.git/.git'
set :version, GitVersion.current(settings.gitdir)
set :erb, :escape_html => true

GOLDCOST = 3.99
DB = SimpleDb.new



configure :development do
	# run the db backup script to make sure the schema we have stored is up to date...
	`./config/db/export-db.sh`

end

configure do

	# we have a table with a list of dates we can join against to do reporting and so on.
	# this should be populated the first time we start the app
	if !DB.date_list_exist?
		puts 'populating the date list. This might take a few minutes...'
		DB.populate_dates
	end
end

get '/' do
	
	fc = FileCache.new
	goldCost = GOLDCOST

	locals = fc.cache('gold.data', 300) do
		data = {
			:dayCount => DB.goldCount(1) * goldCost,
			:weekCount => DB.goldCount(7) * goldCost,
			:monthCount => DB.goldCount(30) * goldCost,
			:dailyData => DB.revenueByDay(30),
			:topComments => DB.topComments(7)[0..5],
			:data_age => DB.last_comment_age
		}

		data = data.merge({ 
			:dayRate => data[:dayCount] / (1 * 24),
			:weekRate => data[:weekCount] / (7 * 24),
			:monthRate => data[:monthCount] / (30 * 24)
		})

		puts 'Cache Refresh'
		data
	end

	erb :index, :layout => :_layout, :locals => locals
end

get '/r/:subreddit' do |subreddit|

	startDate = DB.subredditStart(subreddit)
	halt 404, 'subreddit not found' if startDate.nil?

	locals = FileCache.new.cache "#{subreddit}.data.txt", 300 do
		{
			:subreddit => subreddit,
			:countData => DB.subredditRevenue(subreddit),		
		}
	end

	locals[:startDate] = startDate
	erb :subreddit, :layout => :_layout, :locals => locals
end

get '/gold/this_month' do
	data = DB.revenueSince Time.now.beginning_of_month
	return [200, {'Content-type' => 'text/plain'}, data.to_s]
end


