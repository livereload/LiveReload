<?php

function db_value($arg) {
  if (is_null($arg)) {
    return 'NULL';
  } if (is_numeric($arg)) {
    return "$arg";
  } else {
    return '"' . mysql_real_escape_string("$arg") . '"';
  }
}

function db_query_array($sql, $args=array()) {
  $escaped = array();
  $index = 1;
  foreach ($args as $arg) {
    $k = ':' . $index++;
    $escaped[$k] = db_value($arg);
  }

  $sql = strtr($sql, $escaped);

  if (defined('SQL_LOG')) {
    $fd = fopen(SQL_LOG, 'a');
    fwrite($fd, "$sql\n");
    fclose($fd);
  }

  return mysql_query($sql);
}

function db_query($sql) {
  $args = func_get_args();
  array_shift($args);
  return db_query_array($sql, $args);
}

function execute_array($sql, $args=array()) {
  $result = db_query_array($sql, $args);
  if ($result === FALSE) {
    trigger_error("Query failed in execute: {$sql}", E_USER_ERROR);
  }
  if (is_resource($result)) {
    mysql_free_result($result);
  }
  return mysql_affected_rows();
}

function execute() {
  $args = func_get_args();
  $sql = array_shift($args);
  execute_array($sql, $args);
}

function execute_nofail() {
  $args = func_get_args();
  $result = call_user_func_array('db_query', $args);
  if (is_resource($result)) {
    mysql_free_result($result);
  }
  return mysql_affected_rows();
}

function query_rows() {
  $args = func_get_args();

  $class = 'stdClass';
  if (class_exists($args[0])) {
    $class = array_shift($args);
  }

  $result = call_user_func_array('db_query', $args);
  if (empty($result)) {
    trigger_error("Query failed in query_rows: {$args[0]}", E_USER_ERROR);
  }
  $rows = array();
  while ($row = mysql_fetch_object($result, $class)) {
    $rows[] = $row;
  }
  return $rows;
}

function query_rows_arrays() {
  $args = func_get_args();
  $result = call_user_func_array('db_query', $args);
  if (empty($result)) {
    trigger_error("Query failed in query_rows_arrays: {$args[0]}", E_USER_ERROR);
  }
  $rows = array();
  while ($row = mysql_fetch_array($result)) {
    $rows[] = $row;
  }
  return $rows;
}

function query_row() {
  $args = func_get_args();
  $rows = call_user_func_array('query_rows', $args);
  if (count($rows) > 1)
    trigger_error("More than 1 row returned in query_row: {$args[0]}", E_USER_ERROR);
  else if (count($rows) > 0)
    return $rows[0];
  else
    return null;
}

function query_row_array() {
  $args = func_get_args();
  $rows = call_user_func_array('query_rows_arrays', $args);
  if (count($rows) > 1)
    trigger_error("More than 1 row returned in query_row_array: {$args[0]}", E_USER_ERROR);
  else if (count($rows) > 0)
    return $rows[0];
  else
    return null;
}

function query_values() {
  $args = func_get_args();
  $result = call_user_func_array('db_query', $args);
  $values = array();
  while ($row = mysql_fetch_array($result)) {
    foreach($row as $k => $v) {
      $values[] = $v;
      break;
    }
  }
  return $values;
}

function query_value() {
  $args = func_get_args();
  $values = call_user_func_array('query_values', $args);
  if (count($values) > 1)
    trigger_error("More than 1 row returned in query_value: {$args[0]}", E_USER_ERROR);
  else if (count($values) > 0)
    return $values[0];
  else
    return null;
}

function query_count() {
  $args = func_get_args();
  $value = call_user_func_array('query_value', $args);
  return is_null($value) ? 0 : $value;
}

function db_update($table, $values, $where) {
  $args = func_get_args();
  array_shift($args); array_shift($args); array_shift($args);

  $sets = array();
  foreach($values as $key => $value) {
    if (preg_match('/__sql$/', $key)) {
      $key = substr($key, 0, strlen($key) - 5);
    } else {
      $value = db_value($value);
    }
    $sets[] = "`$key` = $value";
  }
  $sets = implode(", ", $sets);

  execute_array("UPDATE `$table` SET $sets WHERE $where", $args);
}

function db_insert($table, $values) {
  $sets = array();
  $args = array();
  foreach($values as $key => $value) {
    if (preg_match('/__sql$/', $key)) {
      $key = substr($key, 0, strlen($key) - 5);
      $args[] = $value;
    } else {
      $args[] = db_value($value);
    }
    $sets[] = "`$key`";
  }
  $sets = implode(", ", $sets);
  $args = implode(", ", $args);

  execute_array("INSERT INTO `$table` ($sets) VALUES ($args)");

  return mysql_insert_id();
}
