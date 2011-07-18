<?php

require_once("NFSN/RemoteAddr.php");

$email = $_REQUEST['email'];
$message = $_REQUEST['message'];
$ip = LastRemoteAddr();
$agent = urldecode($_SERVER['HTTP_USER_AGENT']);
$time = time();

if (!empty($email)) {
    if (empty($iversion)) {
        $iversion = $version;
    }
    mysql_connect('omega.db', 'livereload', 'TdDmCHrUhYV4qKrN');
    mysql_select_db('livereload');

    $sql = sprintf('INSERT INTO subscriptions(time, ip, email, message, agent) VALUES(%s, "%s", "%s", "%s", "%s")',
        $time,
        mysql_real_escape_string($ip),
        mysql_real_escape_string($version),
        mysql_real_escape_string($iversion),
        mysql_real_escape_string($agent));

    mysql_query($sql);

    $msg = "Subscriber: $email\nIP: $ip\nUser Agent: $agent\n\nMessage:\n$message\n\n-- LiveReload";
    mail('andreyvit@me.com', "LiveReload subscription: $email", $msg, "From: notification@livereload.com\r\nReply-To: $email");

    echo 'ok';
} else {
    echo 'failed';
}
