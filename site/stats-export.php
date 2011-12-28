<?php

require 'framework/framework.php';
mysql_connect('omega.db', 'livereload', 'TdDmCHrUhYV4qKrN');
mysql_select_db('livereload');

$start = 0;
$limit = 10;
if (isset($_GET['start']))
  $start = (int)$_GET['start'];
if (isset($_GET['limit']))
  $limit = (int)$_GET['limit'];

$since = "2001-01-01";
if (isset($_GET['since']) && preg_match('/^\\d{4}-\\d{1,2}-\\d{1,2}$/', $_GET['since']))
  $since = $_GET['since'];


$rows = query_rows("SELECT * FROM stats WHERE date > '$since' ORDER BY date LIMIT $start, $limit");

ob_start("ob_gzhandler");
header("Content-type: application/json");

echo json_encode($rows);
