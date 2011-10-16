<!DOCTYPE html>
<meta charset="UTF-8" />
<style>
    html, body {
        font: 16px Helvetica;
        line-height: 20px;
    }
    h1 {
        font-size: 20px;
        line-height: 30px;
        margin: 20px 0px 10px;
    }
    td, th {
        padding: 2px 10px;
        border-bottom: 1px solid black;
    }
    table.horizontal th {
        text-align: left;
    }
    tr.active_user_count, tr.growth_fmt {
        font-weight: bold;
        background: #eee;
    }
    tr.growth_fmt td.positive {
        color: green;
    }
    tr.growth_fmt td.negative {
        color: red;
    }
</style>
<?php

require 'framework/framework.php';
mysql_connect('omega.db', 'livereload', 'TdDmCHrUhYV4qKrN');
mysql_select_db('livereload');

function table($caption, $headers, $rows, $extra='') {
    $e = array();
    $th = array();
    $keys = array();
    foreach ($headers as $k => $header) {
        $th[] = html_tag('th', $e, $header);
        $keys[] = $k;
    }
    $tr = array();
    foreach ($rows as $row) {
        $td = array();
        foreach ($keys as $key) {
            if (is_object($row)) {
                $v = $row->$key;
            } else {
                $v = $row[$key];
            }
            $td[] = html_tag('td', $e, "$v");
        }
        $tr[] = html_tag('tr', $e, $td);
    }

    return html_tag('h1', $e, $caption) . $extra .
        html_tag('table', array('cellspacing' => '0'),
            html_tag('thead', $e, html_tag('tr', $e, $th)),
            html_tag('tbody', $e, $tr));
}

function inv_table($caption, $headers, $rows, $extra='') {
    $e = array();
    $tr = array();
    foreach ($headers as $key => $header) {
      $td = array();
      $td[] = html_tag('th', $e, $header);
      foreach ($rows as $index => $row) {
        if (is_object($row)) {
            $v = $row->$key;
        } else {
            $v = $row[$key];
        }
        $classes = '';
        if ((float) $v < 0)
          $classes = 'negative';
        else
          $classes = 'positive';
        if ($index == count($rows) - 1) {
          $classes = "$classes last";
        }
        $td[] = html_tag('td', array('class' => $classes), "$v");
      }
      $tr[] = html_tag('tr', array('class' => $key), $td);
    }

    return html_tag('h1', $e, $caption) . $extra .
        html_tag('table', array('cellspacing' => '0', 'class' => 'horizontal'),
            html_tag('thead', $e, html_tag('tr', $e, $th)),
            html_tag('tbody', $e, $tr));
}

function chart($data) {
    $chart = "https://chart.googleapis.com/chart?chs=300x125&chg=0,25&cht=ls&chco=0077CC&chxt=y&chxr=0,0,400&chds=0,400&chd=t:" . implode(',', $data);
    return div('', html_tag('img', array('src' => $chart)));
}

function stats_before($time) {
  return query_rows(
    "SELECT ip,
          FROM_UNIXTIME(MIN(time)) start,
          FROM_UNIXTIME(MAX(time)) end,
          (MAX(time)-MIN(time))/(60*60*24) AS active_period,
          ($time-MAX(time))/(60*60*24) AS inactive_period,
          ($time-MIN(time))/(60*60*24) AS age
      FROM `stats`
      WHERE time <= $time
      GROUP BY ip
      ORDER BY active_period DESC");
}

function start_of_week($now) {
  $info = (object) getdate($now);
  $last_sun_start = mktime(0, 0, 0, $info->mon, $info->mday - $info->wday, $info->year);
  return $last_sun_start + 24 * 60 * 60;
}

function start_of_month($now) {
  $info = (object) getdate($now);
  return mktime(0, 0, 0, $info->mon, 1, $info->year);
}

function advance_week($start_of_week, $delta) {
  return $start_of_week + $delta * 7 * 24 * 60 * 60;
}

function advance_month($start_of_month, $delta) {
  $info = (object) getdate($start_of_month);
  return mktime(0, 0, 0, $info->mon + $delta, 1, $info->year);
}


define('PERIOD_WEEK', 7);
define('PERIOD_MONTH', 30);

function start_of_period($period_length, $time) {
  if ($period_length == PERIOD_WEEK) {
    return start_of_week($time);
  } else {
    return start_of_month($time);
  }
}

function advance_period($period_length, $start_of_period, $delta) {
  if ($period_length == PERIOD_WEEK) {
    return advance_week($start_of_period, $delta);
  } else {
    return advance_month($start_of_period, $delta);
  }
}

define('STATUS_TRIAL', 0);
define('STATUS_ACTIVE', 1);
define('STATUS_INACTIVE', 2);
define('TRIAL_PERIOD', 7);
define('INACTIVITY_CUTOFF', 14);

function grouped_stats($period_length, $period_count) {
  $now = time();
  $week0 = start_of_week($now);
  $weeks = array();
  for ($i = $period_count; $i >= 0; $i--) {
    $week = new stdClass;
    $week->start = advance_period($period_length, $week0, -$i);
    $week->end = advance_period($period_length, $week->start, 1); // + $period_length * 24 * 60 * 60;
    $week->start_fmt = strftime('%b %d', $week->start);
    $week->period_fmt = strftime('%b %d', $week->start) . ' – ' . strftime('%b %d', $week->end);
    $week->stats = index_by_field('ip', stats_before(min($now, $week->end)));
    foreach ($week->stats as $ip => &$row) {
      if ($row->age < TRIAL_PERIOD)
        $row->status = STATUS_TRIAL;
      else if ($row->inactive_period > INACTIVITY_CUTOFF || $row->inactive_period > $row->active_period)
        $row->status = STATUS_INACTIVE;
      else
        $row->status = STATUS_ACTIVE;
    }
    $weeks[] = $week;
  }

  foreach ($weeks as &$week) {
    if (!empty($last_week)) {
      $week->active_user_count = 0;
      $week->new_users = array();
      $week->gone_users = array();
      $week->trial_users = array();

      $week->users_this_week = 0;
      foreach ($week->stats as $ip => $row) {
        if ($row->inactive_period < $period_length) {
          $week->users_this_week++;
        }
      }

      foreach ($week->stats as $ip => $row) {
        $prev_row = $last_week->stats[$ip];
        if ($row->status == STATUS_ACTIVE) {
          ++$week->active_user_count;
          if (empty($prev_row) || $prev_row->status != STATUS_ACTIVE) {
            $week->new_users[] = $ip;
          }
        }
      }

      foreach ($last_week->stats as $ip => $prev_row) {
        $row = $week->stats[$ip];
        if ($prev_row->status == STATUS_ACTIVE) {
          if (empty($row) || $row->status != STATUS_ACTIVE) {
            $week->gone_users[] = $ip;
          }
        }
      }

      $week->trial_fresh = 0;
      $week->trial_good = 0;
      $week->trial_bad = 0;
      foreach ($week->stats as $ip => $row) {
        if ($row->status == STATUS_TRIAL) {
          $week->trial_users[] = $ip;
          if ($row->age <= 3) {
            $week->trial_fresh++;
          } else if ($row->active_period > $row->inactive_period) {
            $week->trial_good++;
          } else {
            $week->trial_bad++;
          }
        }
      }
      $week->trial_count = count($week->trial_users);

      $week->new_user_count = count($week->new_users);
      $week->gone_user_count = count($week->gone_users);

      $week->growth = ($last_week->active_user_count > 0) ? (float) $week->active_user_count / $last_week->active_user_count - 1 : 0;
      $week->growth_fmt = round($week->growth * 100) . '%';

      $week->delta = ($week->active_user_count - $last_week->active_user_count);

      $week->new_user_growth = ($last_week->new_user_count > 0) ? (float) $week->new_user_count / $last_week->new_user_count - 1 : 0;
      $week->new_user_growth_fmt = round($week->new_user_growth * 100) . '%';

      $week->churn = ($last_week->active_user_count > 0) ? (float) $week->gone_user_count / $last_week->active_user_count : 0;
      $week->churn_fmt = round($week->churn * 100) . '%';
    }
    $last_week = $week;
  }

  array_shift($weeks);  // remove the first week, it was only used to compute futher stats
  return $weeks;
}

function format_grouped_stats($period_length, $period_count, $name, $title) {
  $weeks = grouped_stats($period_length, $period_count);
  return inv_table($title, array(
      'start_fmt' => '',
      'users_this_week' => "Total this $name",
      'active_user_count' => 'Active users',
      'new_user_count' => 'New active users',
      'gone_user_count' => 'Previously active users gone',
      'growth_fmt' => '% increase in active users (growth)',
      'delta' => '∆ active users',
      'new_user_growth_fmt' => '% increase in new users',
      'churn_fmt' => '% previously active users gone (churn)'
    ), $weeks);
}



$count = query_count('SELECT COUNT(DISTINCT ip) AS count FROM stats');
$by_date = query_rows('SELECT date, COUNT(DISTINCT ip) AS count FROM stats GROUP BY date ORDER BY date');
$by_ver_30 = query_rows('SELECT version, COUNT(DISTINCT ip) AS count FROM stats WHERE date > DATE_SUB(NOW(), INTERVAL 30 DAY) GROUP BY version ORDER BY version');
$by_ver_7 = query_rows('SELECT version, COUNT(DISTINCT ip) AS count FROM stats WHERE date > DATE_SUB(NOW(), INTERVAL 7 DAY) GROUP BY version ORDER BY version');
$by_ver_2 = query_rows('SELECT version, COUNT(DISTINCT ip) AS count FROM stats WHERE date > DATE_SUB(NOW(), INTERVAL 2 DAY) GROUP BY version ORDER BY version');
$latest = query_rows('SELECT time, version, ip, agent FROM stats ORDER BY time DESC LIMIT 10');
foreach($latest as &$row) {
    $row->time_fmt = strftime('%Y-%m-%d %H:%M', $row->time);
}

$data = array();
foreach ($by_date as $row) {
    $data[] = $row->count;
}
$data = array_slice($data, -7*10);

echo html_tag('h1', array(), "Total unique IPs: $count");

echo html_tag('h1', array(), "Unique IPs by day, all time") . chart($data);

echo format_grouped_stats(PERIOD_WEEK, 8, "week", "Weekly statistics");
echo format_grouped_stats(PERIOD_MONTH, 8, "month", "Monthly statistics");

echo table('Unique IPs by version, last 30 days', array('version' => 'Version', 'count' => 'IPs'), $by_ver_30);
echo table('Unique IPs by version, last 7 days', array('version' => 'Version', 'count' => 'IPs'), $by_ver_7);
echo table('Unique IPs by version, last 2 days', array('version' => 'Version', 'count' => 'IPs'), $by_ver_2);

echo table('Last 10 pings', array('time_fmt' => 'Date', 'version' => 'Version', 'agent' => 'User Agent'), $latest);

echo table('Unique IPs by day, all time', array('date' => 'Date', 'count' => 'Pings'), array_reverse($by_date));
