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

    $sql = sprintf('INSERT INTO subscriptions(date, ip, email, message, agent) VALUES(%s, "%s", "%s", "%s", "%s")',
        $time,
        mysql_real_escape_string($ip),
        mysql_real_escape_string($email),
        mysql_real_escape_string($message),
        mysql_real_escape_string($agent));

    $r = mysql_query($sql);

    $msg = "Subscriber: $email\nIP: $ip\nUser Agent: $agent\n\nMessage:\n$message\n\n-- LiveReload";
    mail('andreyvit@me.com', "LiveReload subscription: $email", $msg, "From: notification@livereload.com\r\nReply-To: $email");

    if (!$r)
      die('failed')
    echo 'ok';
} else {
    echo 'failed';
}
