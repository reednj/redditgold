<?php

require_once 'lib/db.php';


for($i=0; $i < 100; $i++) {
	$d = date('Y-m-d', strtotime("2000-01-1". ' + '.$i.' days'));
	ESQL::Insert('date_list', array('date_index' => $d));
}




?>
