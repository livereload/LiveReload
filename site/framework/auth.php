<?php

function can($permission, $object=NULL) {
  $user = current_user();
  $role = $user->role;
  if ($role == 'superadmin') {
    return TRUE;
  }
  if ($role && function_exists($func = "can_{$role}_{$permission}")) {
    return call_user_func($func, $user, $object);
  }
  if ($user && function_exists($func = "can_{$permission}")) {
    return call_user_func($func, $user, $object);
  }

  return FALSE;
}

function will($permission, $object=NULL, $exit_url='/', $message='Sorry, you do not have permission to access this page.') {
  if (!can($permission, $object)) {
    if (current_user()) {
      redirect($exit_url, $message);
    } else {
      redirect_to_login($_SERVER['REQUEST_URI'], "Please login to access this page.");
    }
  }
}
