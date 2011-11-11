<?php

require 'framework/framework.php';
mysql_connect('omega.db', 'livereload', 'TdDmCHrUhYV4qKrN');
mysql_select_db('livereload');

if ($_GET['pw'] != '3141jopa') {
  die("Access denied.");
}

header("Content-type: text/csv");

$rows = query_rows("SELECT date, ip, email FROM subscriptions");
foreach($rows as $row) {
  // echo "{$row->date}\t{$row->ip}\t{$row->email}\n";
  echo "{$row->email}\n";
}
