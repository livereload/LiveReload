<?php

function param_id($name, $allow_new=FALSE) {
  $value = $_GET[$name];
  if (empty($value)) {
    die("$name missing.");
  }
  if ($value == 'new') {
    if ($allow_new) {
      return 'new';
    } else {
      die("new not allowed in $name.");
    }
  }
  $result = (int)$value;
  if ($result == 0) {
    die("invalid $name: " . h($value));
  }
  return $result;
}
