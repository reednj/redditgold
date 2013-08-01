<?php
	require_once 'lib/db.php';

	$gold_cost = 3.99;

	$day_count = Comments::GoldCount(1) * $gold_cost;
	$week_count = Comments::GoldCount(7) * $gold_cost;
	$month_count = Comments::GoldCount(30) * $gold_cost;

	$day_rate = $day_count / (1 * 24);
	$week_rate = $week_count / (7 * 24);
	$month_rate = $month_count / (30 * 24);

	$daily_data = Comments::RevenueByDay();
	$subreddit_data = Comments::TopSubreddits();
?>

<!doctype html >
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>gold-counter - tracking revenue from reddit gold</title>

<link rel="stylesheet" href="content/css/base.css" type="text/css" media="screen, projection">

<script type='text/javascript' src='content/js/Chart.min.js'></script>
<script type='text/javascript'>

_daily_data = <?= json_encode($daily_data) ?>;

window.addEvent('load', function() {
	var data = [];
	var labels = [];

	for(var i=0; i < _daily_data.length -1; i++) {
		var day = _daily_data[i];
		data.push(parseFloat(day.revenue, 10));
		labels.push(day.day);
	}

	var ctx = $('weekly-chart').getContext('2d');
	var chart = new Chart(ctx).Bar({
		labels: labels,
		datasets: [
			{
				fillColor : "rgba(255,153,50, 0.7)",
				strokeColor : "rgb(255,153,50)",
				data: data
			}
		]
	},
	{
		scaleStartValue: 0,
		barValueSpacing: 1,
		barStrokeWidth: 1
	});
});

function addEvent(event, fn) {
    if (window.addEventListener) {
        window.addEventListener(event, fn, false);
    } else if (window.attachEvent) {
        window.attachEvent('on' + event, fn);
    }
}

function $(id) {
	return document.getElementById(id);
}

</script>

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

		<div class='so-counter-block last'>
			<div class='so-counter'> $<?= number_format($day_count); ?> </div>
			<div class='so-label'> last 24 hrs <span class='so-rate'> ($<?= number_format($day_rate, 2); ?> / hr)</span> </div>
		</div>


		<div class='clear'></div>

	</div>

	<div class='clear'></div>

	<canvas id="weekly-chart" width="605" height="220"></canvas>

	<div class='clear'></div>

	<div class='block last' style='display:none'>

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
