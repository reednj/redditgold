
class SimpleDb
	def initialize
		@db = nil
		@gold_cost = 3.99
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

	def gold_count(day_count)
		return gold_since(Time.now - day_count.days)
	end
	
	def gold_since(date)
		return self.db.from(:comments).where{ created_date > date }.sum(:gold_change) || 0
	end

	def revenue_since(date)
		return gold_since(date) * @gold_cost
	end

	def top_comments(days)
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
		", @gold_cost, days].all
	end

	def revenue_by_subreddit(days)

		return self.db["select
				subreddit,
				count(*) * ? as revenue
			from comments
			where created_date > (now() - interval '?' day)
			group by subreddit
			order by count(*) desc
			limit 12", @gold_cost, days].all;
	end

	def revenue_by_day(day_lookup)
		since_date = Time.now - day_lookup.days

		return self.db["select
				date_index as comment_date,
				day(date_index) as day,
				COALESCE(sum(c.gold_change),0) * ? as revenue
			from date_list dl
				inner join comments c on date(c.created_date) = date(dl.date_index)
			where dl.date_index < now()
				and c.date_index > ? and
				and c.created_date > ?
			group by dl.date_index", @gold_cost, since_date, since_date].all;
	end

	def revenue_by_week(since_date=nil)
		since_date ||= 12.weeks.ago

		return self.db["select
				min(date_index) as date,
				year(date_index) as year,
				week(date_index) as month,
				COALESCE(sum(g.gold_profit),0) as revenue
			from date_list dl
				left join gold_summary g on g.summary_date = date(dl.date_index)
			where
				dl.date_index < now() and
				dl.date_index > ?
			group by year(date_index), week(date_index)", since_date].all;
	end

	def revenue_by_month(since_date=nil)
		since_date ||= 52.weeks.ago

		return self.db["select
				min(date_index) as date,
				year(date_index) as year,
				month(date_index) as month,
				COALESCE(sum(g.gold_profit),0) as revenue
			from date_list dl
				left join gold_summary g on g.summary_date = date(dl.date_index)
			where
				dl.date_index < now() and
				dl.date_index > ?
			group by year(date_index), month(date_index)", since_date].all;
	end

	def revenue_by_year(since_date=nil)
		since_date ||= Time.parse('2012-12-31')

		return self.db["select
				min(date_index) as date,
				year(date_index) as year,
				COALESCE(sum(g.gold_profit),0) as revenue
			from date_list dl
				left join gold_summary g on g.summary_date = date(dl.date_index)
			where
				dl.date_index < now() and
				dl.date_index >= ?
			group by year(date_index)", since_date].all;
	end

	def subreddit_start(subreddit)
		self.db[:comments].where(:subreddit => subreddit).min(:created_date)
	end

	def subreddit_revenue(subreddit)
		self.db[:comments].where(:subreddit => subreddit).count * @gold_cost
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

#
# These extensions should really be moved out into their own file...
#
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
		self.to_s.commas
	end

	def to_usd(precision=2)
		s = '$' + ("%.#{precision}f" % self.abs)
		s = '-' + s if self < 0
		return s.commas
	end

	def to_minutes
		self / 60.0
	end

	def to_pct
		return 0.to_pct if self.nan?
		(self >= 0 ? '+' : '') + ('%.2f' % (self * 100)) + ' %'
	end
end

class Fixnum
	def nan?
		false
	end

	def ago
		Time.now - self
	end

	def from_now
		Time.now + self
	end

	def seconds
		self
	end

	def minutes
		self * 60
	end

	def hours
		self * 60.minutes
	end

	def days
		self * 24.hours
	end

	def weeks
		self * 7.days
	end

	alias minute minutes
	alias hour hours
	alias day days
	alias week weeks
end

class String
	def commas
		self =~ /([^\.]*)(\..*)?/
		int, dec = $1.reverse, $2 ? $2 : ""
		while int.gsub!(/(,|\.|^)(\d{3})(\d)/, '\1\2,\3')
		end
		int.reverse + dec
	end

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