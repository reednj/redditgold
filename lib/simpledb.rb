

class SimpleDb
	def initialize
		@db = nil
		@GoldCost = 3.99
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
	
	def topComments(days)
		return self.db["
			select
				c.comment_id,
				c.thread_id,
				count(*) as gold_count,
				count(*) * #{@GoldCost} as revenue,
				c.user,
				cc.content as comment_text
			from comments c 
				inner join comment_content cc on cc.comment_id = c.comment_id
			where created_date > now() - interval #{days} day
			group by c.comment_id
			order by count(*) desc
			limit 100
		"].all
	end

	def revenueBySubreddit(days)

		return self.db["select
				subreddit,
				count(*) * #{@GoldCost} as revenue
			from comments
			where created_date > (now() - interval '#{days}' day)
			group by subreddit
			order by count(*) desc
			limit 12"].all;
	end

	def revenueByDay(days)

		return self.db["select
				date_index as comment_date,
				day(date_index) as day,
				((select count(*) from comments where date(created_date) = date(dl.date_index)) * #{@GoldCost}) as revenue
			from date_list dl
			where
				dl.date_index < now() &&
				dl.date_index > now() - INTERVAL '#{days}' day"].all;
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


