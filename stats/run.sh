#! /bin/bash
node bin/download.js
node bin/process.js rawtodaily raw day-events "$@"

node bin/process.js reduce day-events month-events "$@"
node bin/process.js reduce day-events year-events "$@"

node bin/process.js reducetemp month-events month-events-cum "$@"
node bin/process.js reducetemp year-events year-events-cum "$@"

node bin/process.js userinfo month-events-cum month-users "$@"
