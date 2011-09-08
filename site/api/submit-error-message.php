<?php

require_once("NFSN/RemoteAddr.php");

// CREATE TABLE unparsable_logs(id int primary key auto_increment, time int not null, date date not null, ip varchar(100) not null, version varchar(100) not null, iversion varchar(100) not null, agent varchar(255) not null, compiler varchar(100) not null, body text not null, index (date))

$version = $_GET['v'];
$iversion = $_GET['iv'];
$compiler = $_GET['compiler'];
$ip = LastRemoteAddr();
$agent = urldecode($_SERVER['HTTP_USER_AGENT']);
$time = time();
$body = http_get_request_body();

if (!empty($version) && !empty($iversion) && !empty($compiler)) {
    mysql_connect('omega.db', 'livereload', 'TdDmCHrUhYV4qKrN');
    mysql_select_db('livereload');

    $sql = sprintf('INSERT INTO unparsable_logs(time, date, ip, version, iversion, agent, compiler, body) VALUES(%s, FROM_UNIXTIME(%s), "%s", "%s", "%s", "%s", "%s", "%s")',
        $time, $time,
        mysql_real_escape_string($ip),
        mysql_real_escape_string($version),
        mysql_real_escape_string($iversion),
        mysql_real_escape_string($agent),
        mysql_real_escape_string($compiler),
        mysql_real_escape_string($body));

    if (!mysql_query($sql)) {
      header("500 Server Error\r\n");
      die("Internal error, saving failed: " . mysql_error());
    }

    $id = mysql_insert_id();
    $msg = "Unparsable log record $id for compiler $compiler.\n\nIP: $ip\nUser Agent: $agent\n\nLog:\n$body\n\n-- LiveReload";
    mail('andreyvit@me.com', "[LiveReload] Unparsable log for $compiler", $msg, "From: notification@livereload.com\r\nReply-To: andreyvit@me.com");

    die("OK.");
} else {
  header("400 Bad Request\r\n");
  die("Bad request.");
}
