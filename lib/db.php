<?php

require_once 'lib/esql.inc.php';

Class Comments {
	static function GoldCount($dayCount) {
		$dayCount = ESQL::Escape($dayCount);
		return ESQL::QueryFirstField("select count(*) from comments where created_date > now() - INTERVAL '$dayCount' DAY");
	}

	static function TopSubreddits($dayCount = 30) {
		$dayCount = ESQL::Escape($dayCount);
		$gold_cost = 3.99;

		return ESQL::Query("
			select
				subreddit,
				count(*) * $gold_cost as revenue
			from comments
			where created_date > (now() - interval '$dayCount' day)
			group by subreddit
			order by count(*) desc
			limit 12
		");
	}

	static function RevenueByWeek($dayCount = 120) {
		$dayCount = ESQL::Escape($dayCount);
		$gold_cost = 3.99;

		return ESQL::Query("
			select
				year(created_date) as year,
				week(created_date) as week,
				count(*) * $gold_cost as revenue
			from comments
			where created_date > (now() - interval '$dayCount' day)
			group by year(created_date), week(created_date)
			order by year(created_date), week(created_date)
		");
	}

	static function Insert($data) {
		return ESQL::Insert('comments', $data);
	}

	static function LastCommentID() {
		return ESQL::QueryFirstField('select comment_id from comments order by gold_id desc limit 1');
	}

}


?>