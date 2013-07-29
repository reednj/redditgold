<?php
	require_once 'lib/db.php';

	$gold_cost = 3.99;

	$day_count = Comments::GoldCount(1) * $gold_cost;
	$week_count = Comments::GoldCount(7) * $gold_cost;
	$month_count = Comments::GoldCount(30) * $gold_cost;

	$day_rate = $day_count / (1 * 24);
	$week_rate = $week_count / (7 * 24);
	$month_rate = $month_count / (30 * 24);

	$weekly_data = Comments::RevenueByWeek();
	$subreddit_data = Comments::TopSubreddits();
?>

<!doctype html >
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title> reddit gold </title>

<link rel="stylesheet" href="content/css/base.css" type="text/css" media="screen, projection">

</head>

<body>

<div class="wrapper">

<div class='so-header'>
	<div class='so-title'>
		<a href='/'><b >gold</b>counter</a>
		<div class='sub-title'>tracking revenues from <a href='http://www.reddit.com/gold/about'>reddit gold</a></div>
	</div>
</div>

<div class='so-body'>

	<div class='so-counter-list'>

		<div class='so-counter-block'>
			<div class='so-counter'> $<?= number_format($month_count); ?> </div>
			<div class='so-label'> last month <span class='so-rate'> ($<?= number_format($month_rate, 2); ?> / hr)</span> </div>
		</div>

		<div class='so-counter-block'>
			<div class='so-counter'> $<?= number_format($week_count); ?> </div>
			<div class='so-label'> last week <span class='so-rate'> ($<?= number_format($week_rate, 2); ?> / hr)</span> </div>
		</div>

		<div class='so-counter-block'>
			<div class='so-counter'> $<?= number_format($day_count); ?> </div>
			<div class='so-label'> last 24 hrs <span class='so-rate'> ($<?= number_format($day_rate, 2); ?> / hr)</span> </div>
		</div>

		<div class='clear'></div>

	</div>

	<div class='clear'></div>

	<div class='block'>

		<table>
			<thead>
				<tr>
					<td colspan='2'><h2>Revenue by Week</h2></td>
				</tr>
			</thead>

			<tbody>
			<?php foreach($weekly_data as $week) { ?>

			<tr>
				<td><?= $week['year'].'-'.$week['week'] ?></td>
				<td>$<?= number_format($week['revenue']) ?></td>
			</tr>

			<?php } ?>
			</tbody>
		</table>
	</div>

	<div class='clear'></div>

	<div class='block'>

		<table>
			<thead>
				<tr>
					<td colspan='2'><h2>Top Subreddits</h2></td>
				</tr>
			</thead>

			<tbody>
			<?php foreach($subreddit_data as $subreddit) { ?>

			<tr>
				<td><?= $subreddit['subreddit'] ?></td>
				<td>$<?= number_format($subreddit['revenue']) ?></td>
			</tr>

			<?php } ?>
			</tbody>
		</table>
	</div>

	<div class='clear'></div>

</div>

<div class="push"></div>
</div>

<div class="footer">

	<div>
		<p>These numbers only include gifted gold, and don't take into account transaction fees etc.</p>
		<p>
			<a href='http://twitter.com/reednj'>Nathan Reed</a> (c) 2013 |

			<a href='http://reddit-stream.com'>reddit-stream.com</a>
		</p>
		<p>
			<a href='http://twitter.com/reednj'>@reednj</a> |
			<a href='http://github.com'>v1.02</a>
		</p>
	</div>

</div>

</body>
</html>
