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
				month(created_date) as month,
				count(*) * $gold_cost as revenue
			from comments
			where created_date > (now() - interval '$dayCount' day)
			group by year(created_date), week(created_date)
			order by year(created_date), week(created_date)
		");
	}

	static function RevenueByDay($dayCount = 30) {
		$dayCount = ESQL::Escape($dayCount);
		$gold_cost = 3.99;

		return ESQL::Query("
			select
				date_index as comment_date,
				day(date_index) as day,
				((select count(*) from comments where date(created_date) = date(dl.date_index)) * $gold_cost) as revenue
			from date_list dl
			where
				dl.date_index < now() &&
				dl.date_index > now() - INTERVAL '$dayCount' day
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