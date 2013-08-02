<?php
/*
 * esql functions designed to make working with mysql in php a little
 * bit easier.
 *
 * Created: 2010-09-16
 * License: MIT-style License
 * Nathan Reed (c) 2010
 */

// dbpass.php should contain your username & password etc
require_once 'config/esql.dbpass.php';

abstract class ESQLTable {

    public static function Select($options=array()) {
        return ESQL::Select(get_called_class(), $options);
    }

    public static function Insert($values) {
        return ESQL::Insert(get_called_class(), $values);
    }

    public static function Update($update_array, $where_obj=null) {
        return ESQL::Update(get_called_class(), $update_array, $where_obj);
    }

    public static function Delete($where_obj) {
        return ESQL::Delete(get_called_class(), $options);
    }
}

class ESQL {
    protected static $db = null;

    public static function Open() {
        self::$db = esql_conn();
        return self::$db;
    }

    public static function Close() {
        if(self::$db === null) { return false; }
        return esql_close();
    }

    public static function Query($query) {
        if(self::$db === null) {self::$db = self::Open();}
        return esql_query($query);
    }

    public static function QueryFirstRow($query) {
        if(self::$db === null) {self::$db = self::Open();}

        $data = esql_query($query);
        return ($data != false)? $data[0] : false;
    }

    public static function QueryFirstField($query) {
        $row = self::QueryFirstRow($query);
        return ($row != false)? current($row) : false;
    }

    public static function Select($table, $options=array()) {
        if(self::$db === null) {self::$db = self::Open();}
        return esql_select($table, $options);
    }

    public static function SelectFirstRow($table, $options=array()) {
        if(self::$db === null) {self::$db = self::Open();}

        $options['limit'] = 1;
        $data = esql_select($table, $options);
        return ($data != false)? $data[0] : false;
    }

    public static function SelectFirstField($table, $options=array()) {
        $row = self::SelectFirstRow($table, $options);
        return ($row != false)? current($row) : false;
    }

    public static function Insert($table, $values) {
        if(self::$db === null) {self::$db = self::Open();}
        return esql_insert($table, $values);
    }

    public static function Update($table, $update_array, $where_obj=null) {
        if(self::$db === null) {self::$db = self::Open();}
        return esql_update($table, $update_array, $where_obj);
    }

    public static function Delete($table, $where_obj) {
        if(self::$db === null) {self::$db = self::Open();}
        return esql_delete($table, $where_obj);
    }

    public static function Escape($val) {
        if(self::$db === null) {self::$db = self::Open();}
        return esql_escape($val);
    }
}

function esql_conn()
{

	// these _ESQL consts should be stored in the dbpass.php header
	$dbuser = _ESQL_USER;
	$dbpass = _ESQL_PASS;
	$dbhost = _ESQL_HOST;
	$dbname = _ESQL_DBNAME;

	$dbconn = mysql_connect($dbhost, $dbuser, $dbpass) or die ('Error connecting to Server');
	mysql_select_db($dbname) or die('Error connecting to DB');

   	esql_query("SET NAMES 'utf8' COLLATE 'utf8_unicode_ci'");

	return $dbconn;
}


function esql_close()
{
	mysql_close();
}

function esql_select($table, $options=array())
{

    $column_list = isset($options['column_list'])? $options['column_list'] : null;
    $where_obj = isset($options['where'])? $options['where'] : null;
    $order_by = isset($options['order_by'])? $options['order_by'] : null;
    $limit = isset($options['limit'])? $options['limit'] : 1000;

    $table = mysql_real_escape_string($table);
    $where_str = esql_build_where($where_obj);

    if(is_array($column_list)) {
        $column_list = escape_values($column_list);
        $column_str = '`'.join($column_list, '`, `').'`';
    } else {
        $column_str = '*';
    }


    $sql_query = "select $column_str from `$table` $where_str";

    if($order_by) {
        $sql_query .= " order by $order_by";
    }

    if(is_numeric($limit)) {
        $sql_query .= " limit $limit";
    }

    return esql_query($sql_query);
}

function esql_insert($table, $values)
{
    $table = mysql_real_escape_string($table);

    // first we need to escape all the values that are getting inserted
    $values = escape_values($values);

    // build up the sql string, making sure to put everything in quotes correctly
    $value_list = "'".join($values, "', '")."'";
    $names_list = '`'.join(array_keys($values), '`, `').'`';
    $sql_string = "insert into `$table` ($names_list) values ($value_list)";

    return esql_query($sql_string);
}

function esql_update($table, $update_array, $where_obj=null)
{
    $table = mysql_real_escape_string($table);
    $update_array = escape_values($update_array);

    $set_list = array();
    foreach($update_array as $field => $value) {
        array_push($set_list, "`$field` = '$value'");
    }

    $set_str = join($set_list, ', ');
    $where_str = esql_build_where($where_obj);
    $sql_string = "update `$table` set $set_str $where_str";

    return esql_query($sql_string);
}

function esql_delete($table, $where_obj)
{
    $table = mysql_real_escape_string($table);
    $where_str = esql_build_where($where_obj);
    $sql_string = "delete from `$table` $where_str";
    return esql_query($sql_string);
}

// the where can either be a simple string, or an array
// of the from field => value. (obviously this can only be used for
// equal clauses)
function esql_build_where($where_obj=null)
{
    if($where_obj == null) {
    	return '';
    }

    if(is_string($where_obj)) {
        $where_kw = 'where';
        $where_obj = trim($where_obj);

        // does the string start with 'where'? if not then add it
        if(substr($where_obj, 0, strlen($where_kw )) != $where_kw ) {
            $where_obj = "$where_kw $where_obj";
        }

        // our job is just to normalize $where_obj to a condition string
        // if they already passed in a string then we are done.
        return $where_obj;
    }

    if(is_array($where_obj)) {
        $condition_list = array();
        foreach($where_obj as $field => $value) {
            array_push($condition_list, "`$field` = '$value'");
        }

        return 'where '.join($condition_list, ' and ');
    }

    return 'where 0';
}

// sql_escape each value in the array
function escape_values($array)
{
    foreach($array as &$val) {
        $val = mysql_real_escape_string($val);
    }

    return $array;
}

function esql_escape($val)
{
    return mysql_real_escape_string($val);
}

function esql_query($query, $dbconn = null)
{
	$data = null;

	if($dbconn == null) {
		$qr = mysql_query($query);
	} else {
		$qr = mysql_query($query, $dbconn);
	}

	// if we got some data back then put it into the data
	// structure ready to return
	if(gettype($qr) == 'resource') {
		for($i=0; $i < mysql_num_rows($qr); $i++) {
			$data[$i] = mysql_fetch_array($qr, MYSQL_ASSOC);
		}
	} else {
		// no data back, but it might have been an INSERT or something, so
		// check that it was successful
		if($qr == true) {
			$data = true;
		} else {
            $data = false;
        }
	}

	return $data;
}

?>
