<?php

require_once("NFSN/RemoteAddr.php");

$version = $_GET['v'];
$iversion = $_GET['iv'];
$ip = LastRemoteAddr();
$agent = urldecode($_SERVER['HTTP_USER_AGENT']);
$time = time();

if (!empty($version)) {
    if (empty($iversion)) {
        $iversion = $version;
    }
    mysql_connect('omega.db', 'livereload', 'TdDmCHrUhYV4qKrN');
    mysql_select_db('livereload');

    $sql = sprintf('INSERT INTO stats(time, date, ip, version, iversion, agent) VALUES(%s, FROM_UNIXTIME(%s), "%s", "%s", "%s", "%s")',
        $time, $time,
        mysql_real_escape_string($ip),
        mysql_real_escape_string($version),
        mysql_real_escape_string($iversion),
        mysql_real_escape_string($agent));

    mysql_query($sql);
}
echo "This file is used to compute anonymous usage statistics and does not contain personally identifiable information.";
