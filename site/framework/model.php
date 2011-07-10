<?php

class Model {

  function is_new() {
    return empty($this->id);
  }
  function is_saved() {
    return !empty($this->id);
  }

  function add_error($field, $message) {
    $error_field = "{$field}_error";
    if (!isset($this->$error_field)) {
      $this->$error_field = $message;
    }
    $this->_has_errors = TRUE;
  }

  function is_valid() {
    return !$this->_has_errors;
  }
  function has_errors() {
    return $this->_has_errors;
  }

  function error($field) {
    $error_field = "{$field}_error";
    return $this->$error_field;
  }

  function update($data, $fields) {
    foreach ($fields as $field) {
      $value = (isset($data[$field]) ? $data[$field] : NULL);
      $this->{"raw_$field"} = $value;
      $this->$field = $value;
    }
    foreach ($fields as $field) {
      $rules = $this->{"{$field}_rules"};
      if (!empty($rules)) {
        foreach ($rules as $rule) {
          if (is_string($rule)) {
            $rule = explode(' ', $rule);
          }

          $args = $rule;
          $rule = array_shift($args);

          $method = "validate_rule_{$rule}";
          $this->$method($field, $args);
          if ($this->error($field))
            break;
        }
      }
      if (method_exists($this, $method = "validate_{$field}")) {
        $this->$method();
      }
    }
    if (method_exists($this, 'validate')) {
      $this->validate();
    }
  }

  function validate_rule_required($field, $args=array()) {
    if (empty($this->$field) && !is_numeric($this->$field)) {
      $this->add_error($field, "Required.");
    }
  }

  function validate_rule_minlen($field, $args=array()) {
    $len = $args[0];
    if (strlen($this->$field) < $len) {
      $this->add_error($field, "Minimum length is $len.");
    }
  }

  function validate_rule_maxlen($field, $args=array()) {
    $len = $args[0];
    if (strlen($this->$field) > $len) {
      $this->add_error($field, "Maximum length is $len.");
    }
  }

  function validate_rule_regexp($field, $args=array()) {
    $message = "Invalid format.";
    if (isset($args['message'])) {
      $message = $args['message'];
      unset($args['message']);
    }

    $re = implode(' ', $args);
    if (!preg_match($re, $this->$field)) {
      $this->add_error($field, $message);
    }
  }

  function validate_rule_email($field, $args=array()) {
    $message = "Invalid e-mail address.";
    if (isset($args['message'])) {
      $message = $args['message'];
      unset($args['message']);
    }

    if (!is_email($this->$field, TRUE)) {
      $this->add_error($field, $message);
    }
  }

  function validate_rule_confirmation($field, $args=array()) {
    $confirmation_field = "{$field}_confirmation";
    if ($this->$field != $this->$confirmation_field) {
      $this->add_error($confirmation_field, "Must match the entered password.");
    }
  }

  function save($fields) {
    $values = array();
    foreach ($fields as $field) {
      $sql_field = "{$field}__sql";
      if (isset($this->$sql_field)) {
        $values[$sql_field] = $this->$sql_field;
      } else {
        $values[$field] = $this->$field;
      }
    }

    if ($this->is_saved()) {
      db_update($this->table_name, $values, "id = :1", $this->id);
    } else {
      $this->id = db_insert($this->table_name, $values);
    }
  }

  function delete() {
    execute("DELETE FROM `{$this->table_name}` WHERE id = :1", $this->id);
  }

}
