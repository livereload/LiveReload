<?php

$body = http_get_request_body();
// mail('andreyvit@me.com', "LiveReload subscription hook", $body, "From: notification@livereload.com");

$result = json_decode($body);

foreach($result->Events as $event) {
  $ip = $event->SignupIPAddress;
  $email = $event->EmailAddress;
  $date  = $event->Date;
  $about = '';
  $notified = FALSE;
  foreach ($event->CustomFields as $field) {
    if ($field->Key == 'About') {
      $about = $field->Value;
    }
  }
  if (!empty($about)) {
    $msg = "Subscriber: $email\nDate: $date\n\nMessage:\n$about\n\n-- LiveReload";
    $notified = mail('andreyvit@me.com', "LiveReload subscription: $email", $msg, "From: notification@livereload.com\r\nReply-To: $email");
  }

  $sql = sprintf('INSERT INTO subscriptions(date, ip, email, message, agent, notified) VALUES(%s, "%s", "%s", "%s", %s)',
      strtotime($date),
      mysql_real_escape_string($ip),
      mysql_real_escape_string($email),
      mysql_real_escape_string($about),
      $notified ? 1 : 0);

  mysql_query($sql);
}

?>
