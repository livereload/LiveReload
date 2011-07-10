<?php

function flash() {
  static $flash_message = NULL;
  if (is_null($flash_message)) {
    if (isset($_SESSION['flash'])) {
      die('$flash_message = ' . $flash_message);
      $flash_message = $_SESSION['flash'];
      unset($_SESSION['flash']);
    } else {
      $flash_message = FALSE;
    }
  }
  return $flash_message;
}

function set_flash($message) {
  $_SESSION['flash'] = $message;
}

function redirect($url, $flash_message=NULL) {
  if ($flash_message) {
    set_flash($flash_message);
  }
  header("Location: $url");
  exit;
}

function render($view, $vars = array()) {
  extract($vars);
  $page_class = "page-" . $view;

  ob_start();
  include ROOT . '/views/' . $view . '.php';
  $content = ob_get_contents();
  ob_end_clean();

  include ROOT . '/views/layout.php';
  exit;
}

function render_json($data) {
  header('Content-Type: application/json');
  echo json_encode($data);
  exit;
}

function render_404() {
  header("{$_SERVER['SERVER_PROTOCOL']} 404 Not Found");
  render('404');
}

function h($str) {
  return htmlspecialchars($str);
}

function l($url, $str, $attrs = array()) {
  return html_tag("a", $attrs + array('href' => $url), $str);
}

function html_tag($tag, $attrs /*, $content1, $content2... */) {
  $data = "$tag";
  foreach ($attrs as $k => $v) {
    if ($k[0] == '#')
      continue;
    if (is_null($v) || $v === false)
      continue;
    if ($v === true)
      $v = $k;
    else if (is_array($v))
      $v = implode(' ', $v);
    $data .= " $k=\"" . htmlspecialchars($v) . "\"";
  }

  $args = func_get_args();
  array_shift($args);
  array_shift($args);

  if (count($args) == 0) {
    return "<$data>";
  } else {
    $content = array();
    foreach ($args as $arg) {
      if (is_array($arg)) {
        $content = array_merge($content, array_flatten($arg));
      } else if (is_null($arg) || $arg === false) {
        # nop
      } else {
        $content[] = "$arg";
      }
    }
    $content = join('', $content);

    if (strpos($content, "\n") === false || $tag == 'textarea') {
      return "<$data>$content</$tag>";
    } else {
      return "<$data>\n$content\n</$tag>";
    }
  }
}

function div($class/*, $content1, $content2... */) {
  $args = func_get_args();
  array_shift($args);

  $attrs = array('class' => $class);
  return html_tag('div', $attrs, $args);
}

function span($class/*, $content1, $content2... */) {
  $args = func_get_args();
  array_shift($args);

  $attrs = array('class' => $class);
  return html_tag('span', $attrs, $args);
}

function html_input($name, $value = '', $attrs = array()) {
  $attrs += array('name' => $name, 'id' => $name, 'value' => $value);
  return html_tag('input', $attrs);
}

function html_password($name, $attrs = array()) {
  $attrs += array('name' => $name, 'id' => $name, 'type' => 'password');
  return html_tag('input', $attrs);
}

function html_checkbox($name, $value=FALSE, $attrs = array()) {
  $attrs += array('name' => $name, 'id' => $name, 'type' => 'checkbox', 'value' => $value);
  $attrs['class'] = "{$attrs['class']} checkbox";
  return html_tag('input', $attrs);
}

function html_textarea($name, $value = '', $attrs = array()) {
  $attrs += array('name' => $name, 'id' => $name);
  return html_tag('textarea', $attrs, h($value));
}

function html_select($name, $options, $value = NULL, $attrs = array()) {
  $attrs += array('#option' => array(), 'name' => $name, 'id' => $name);
  return html_tag('select', $attrs, html_select_options($options, $value, $attrs['#option']));
}

function html_select_options($options, $current_value = NULL, $attrs = array()) {
  foreach ($options as $value => $label) {
    $result[] = html_select_option($value, $label, $current_value, $attrs);
  }
  return $result;
}

function html_select_option($value, $label, $current_value = NULL, $attrs = array()) {
  return html_tag('option', $attrs + array('value' => $value, 'selected' => ($value === $current_value)), $label);
}

function html_submit($label, $name=NULL, $attrs = array()) {
  return html_tag('input', $attrs + array('type' => 'submit', 'value' => $label, 'name' => $name));
}

function form_field($name, $object, $label, $content, $more_classes='') {
  $error_field = "{$name}_error";
  $error = $object->$error_field;
  $classes = array('field', "field-$name", $more_classes);
  if ($error) {
    $classes[] = 'field-error';
    $error_html = html_tag('div', array('class' => 'error'), $error);
  } else {
    $error_html = '';
  }
  return html_tag('div', array('class' => $classes), html_tag('label', array('for' => $name), $label), $content, $error_html);
}

function form_static($name, $object, $label, $options) {
  return form_field($name, $object, $label, h($object->$name));
}

function form_input($name, $object, $label) {
  return form_field($name, $object, $label, html_input($name, $object->$name));
}

function form_textarea($name, $object, $label) {
  return form_field($name, $object, $label, html_textarea($name, $object->$name));
}

function form_password($name, $object, $label) {
  return form_field($name, $object, $label, html_password($name));
}

function form_checkbox($name, $object, $label) {
  return form_field($name, $object, '', html_checkbox($name, $object->$name) . html_tag('label', array('for' => $name, 'class' => 'secondary'), $label), 'field-checkbox');
}

function form_select($name, $object, $label, $options) {
  return form_field($name, $object, $label, html_select($name, $options, $object->$name));
}

function evenodd($id='') {
  static $counters = array();
  if (!isset($counters[$id]))
    $counters[$id] = 1;
  if ($counters[$id]++ % 2 == 0)
    return 'even';
  else
    return 'odd';
}
