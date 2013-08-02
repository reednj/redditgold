# myapp.rb
require 'sinatra'
require "sinatra/reloader" if development?
require 'sequel'
require 'json'


#	$gold_cost = 3.99;

#	$daily_data = Comments::RevenueByDay();
#	$subreddit_data = Comments::TopSubreddits();

get '/' do
	sdb = SimpleDb.new

	goldCost = 3.99
	dayCount = sdb.goldCount(1) * goldCost
	weekCount = sdb.goldCount(7) * goldCost
	monthCount = sdb.goldCount(30) * goldCost

	erb :index, :locals => {
		:dayCount => dayCount,
		:weekCount => weekCount,
		:monthCount => monthCount,
		:dayRate => dayCount / (1 * 24),
		:weekRate => weekCount / (7 * 24),
		:monthRate => monthCount / (30 * 24),
		:dailyData => sdb.revenueByDay(30)
	}
end

#
# this stuff all needs to go out into another file
#




class Numeric
	def commas
		self.to_s =~ /([^\.]*)(\..*)?/
		int, dec = $1.reverse, $2 ? $2 : ""
		while int.gsub!(/(,|\.|^)(\d{3})(\d)/, '\1\2,\3')
		end
		int.reverse + dec
	end
end


AppConfig = OpenStruct.new({
	:db => OpenStruct.new({
		:username => 'linkuser',
		:password => '',
		:host => 'localhost',
		:database => 'gold'
	})
})

class SimpleDb
	def initialize
		@db = nil
	end

	def connect
		@db = Sequel.connect(
			:adapter => 'mysql',
			:user => AppConfig.db.username,
			:host => AppConfig.db.host,
			:database => AppConfig.db.database,
			:password=>AppConfig.db.password
		)
	end

	def db
		if @db != nil
			return @db
		else
			self.connect
			return @db
		end
	end

	def goldCount(days)
		return self.db.from(:comments).where{ created_date > Date.today - days }.count
	end

	def revenueBySubreddit(days)
		goldCost = 3.99

		return self.db["select
				subreddit,
				count(*) * #{goldCost} as revenue
			from comments
			where created_date > (now() - interval '#{days}' day)
			group by subreddit
			order by count(*) desc
			limit 12"].all;
	end

	def revenueByDay(days)
		goldCost = 3.99

		return self.db["select
				date_index as comment_date,
				day(date_index) as day,
				((select count(*) from comments where date(created_date) = date(dl.date_index)) * #{goldCost}) as revenue
			from date_list dl
			where
				dl.date_index < now() &&
				dl.date_index > now() - INTERVAL '#{days}' day"].all;
	end
end
