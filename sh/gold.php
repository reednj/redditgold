<?php

require_once 'lib/db.php';

$data = json_decode(file_get_contents("http://www.reddit.com/r/all/comments/gilded.json?count=50"));
$new_comments = array();
$last_comment = Comments::LastCommentID();

foreach($data->data->children as $comment) {
	if($comment->data->id == $last_comment) {
		break;
	}

	array_push($new_comments, $comment);
}

foreach(array_reverse($new_comments) as $comment) {
	
	print  $comment->data->id . "\n";

	Comments::Insert(array(
		'comment_id' => $comment->data->id,
		'thread_id' => $comment->data->link_id,
		'user' => $comment->data->author,
		'subreddit' => $comment->data->subreddit,
		'gold_count' => $comment->data->gilded,
		'post_date' => date('c', $comment->data->created_utc)
	));
	
	ESQL::Insert('comment_content', array(
		'comment_id' => $comment->data->id,
		'content' => $comment->data->body,
		'title' => $comment->data->link_title
	));
	
	print mysql_error();
}




?>
