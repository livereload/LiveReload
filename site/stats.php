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

function chart($data) {
    $chart = "https://chart.googleapis.com/chart?chs=500x125&cht=ls&chco=0077CC&chxt=y&chxr=0,0,10&chds=0,10&chd=t:" . implode(',', $data);
    return div('', html_tag('img', array('src' => $chart)));
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

echo html_tag('h1', array(), "Total unique IPs: $count");

echo html_tag('h1', array(), "Unique IPs by day, all time") . chart($data);

echo table('Unique IPs by version, last 30 days', array('version' => 'Version', 'count' => 'IPs'), $by_ver_30);
echo table('Unique IPs by version, last 7 days', array('version' => 'Version', 'count' => 'IPs'), $by_ver_7);
echo table('Unique IPs by version, last 2 days', array('version' => 'Version', 'count' => 'IPs'), $by_ver_2);

echo table('Last 10 pings', array('time_fmt' => 'Date', 'version' => 'Version', 'agent' => 'User Agent'), $latest);

echo table('Unique IPs by day, all time', array('date' => 'Date', 'count' => 'Pings'), array_reverse($by_date));
