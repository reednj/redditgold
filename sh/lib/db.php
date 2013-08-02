<?php

require_once 'lib/esql.inc.php';

Class Comments {
	static function Insert($data) {
		return ESQL::Insert('comments', $data);
	}

	static function LastCommentID() {
		return ESQL::QueryFirstField('select comment_id from comments order by gold_id desc limit 1');
	}

}


?>