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

	if(is_thread($comment->data->name)) {
		$thread_id = $comment->data->name;
		$title = $comment->data->title;
		$body = $comment->data->is_self == 1 ? $comment->data->selftext : '';
	} else {
		$thread_id = $comment->data->link_id;
		$title = $comment->data->link_title;
		$body = $comment->data->body;
	}

	Comments::Insert(array(
		'comment_id' => $comment->data->id,
		'thread_id' => $thread_id,
		'user' => $comment->data->author,
		'subreddit' => $comment->data->subreddit,
		'gold_count' => $comment->data->gilded,
		'post_date' => date('c', $comment->data->created_utc)
	));
	
	ESQL::Insert('comment_content', array(
		'comment_id' => $comment->data->id,
		'content' => $body,
		'title' => $title
	));
	
	print mysql_error();
}

function is_thread($id) {
	return strpos($id, 't3_') === 0;
}


?>
