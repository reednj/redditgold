require "sinatra/reloader" if development?

class SimpleDb
	def initialize
		@db = nil
		@GoldCost = 3.99
	end

	def connect
		@db = Sequel.connect(
			:adapter => 'mysql2',
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
	
	def revenueSince(date)
		return self.db.from(:comments).where{ created_date > date }.count * @GoldCost
	end

	def topComments(days)
		return self.db["
			select
				c.comment_id,
				c.thread_id,
				c.subreddit,
				max(gold_count) as gold_count,
				max(gold_count) * ? as revenue,
				c.user,
				cc.content as comment_text,
				cc.title as thread_title
			from comments c 
				inner join comment_content cc on cc.comment_id = c.comment_id
			where post_date > now() - interval ? day
			group by c.comment_id
			order by max(gold_count) desc
			limit 100
		", @GoldCost, days].all
	end

	def revenueBySubreddit(days)

		return self.db["select
				subreddit,
				count(*) * ? as revenue
			from comments
			where created_date > (now() - interval '?' day)
			group by subreddit
			order by count(*) desc
			limit 12", @GoldCost, days].all;
	end

	def revenueByDay(days)

		return self.db["select
				date_index as comment_date,
				day(date_index) as day,
				count(c.comment_id) * ? as revenue
			from date_list dl
				inner join comments c on date(c.created_date) = dl.date_index
			where
				dl.date_index < now() &&
				dl.date_index > now() - INTERVAL '?' day
			group by dl.date_index", @GoldCost, days].all;
	end

	def subredditStart(subreddit)
		self.db[:comments].where(:subreddit => subreddit).min(:created_date)
	end

	def subredditRevenue(subreddit)
		self.db[:comments].where(:subreddit => subreddit).count * @GoldCost
	end

	def last_comment
		self.db[:comments].reverse_order(:created_date).limit(1)
	end

	def last_comment_age
		created_date = self.last_comment.get(:created_date)
		created_date.nil? ? -1 : created_date.age
	end

	def populate_dates
		start_date = Date.parse('2000-01-01')
		end_date = Date.parse('2030-12-31')

		(start_date..end_date).each do |d|
			self.db[:date_list].insert :date_index => d
		end
	end

	def date_list_exist?
		!self.db[:date_list].first.nil?
	end
end

class Time
	def beginning_of_month
		Time.parse(self.strftime("%Y-%m-01"))
	end

	def age
		Time.now - self
	end
end

class Numeric
	def commas
		self.to_s =~ /([^\.]*)(\..*)?/
		int, dec = $1.reverse, $2 ? $2 : ""
		while int.gsub!(/(,|\.|^)(\d{3})(\d)/, '\1\2,\3')
		end
		int.reverse + dec
	end

	def to_minutes
		self / 60.0
	end
end

class String
	def truncate(len, omission='...')
		if self.length <= len
			return self 
		else
			return self[0, len].strip + omission
		end
	end
end

class GitVersion
	def self.current(gitdir='./.git')
		return `git --git-dir=#{gitdir} describe --long --always`
	end
end