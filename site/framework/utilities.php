<?php

function random_string($length=20, $chars='ABCDEFGHIJKLMNPRSTUVWXYZabcdefghijklmnprstuvwxyz123456789') {
  $random = "";
  $c = strlen($chars);
  for($i = 0; $i < $length; $i++) {
    $random .= substr($chars, mt_rand(0, $c-1), 1);
  }
  return $random;
}

function index_by_field($field, $array) {
  $result = array();
  foreach ($array as $item) {
    $item = (object) $item;
    $result[$item->$field] = $item;
  }
  return $result;
}

function group_by_field($field, $array) {
  $result = array();
  foreach ($array as $item) {
    $item = (object) $item;
    $key = $item->$field;

    if (!isset($result[$key])) {
      $result[$key] = array();
    }
    $result[$key][] = $item;
  }
  return $result;
}

function array_flatten($array, &$result=array()) {
  foreach ($array as $item){
    if(is_array($item)) {
      array_flatten($item, $result);
    } else {
      $result[] = $item;
    }
  }
  return $result;
}

function format_date_ago($date) {
  return $date;
}

function isxhr() {
  return isset($_SERVER['HTTP_X_REQUESTED_WITH']) && strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) == 'xmlhttprequest';
}
