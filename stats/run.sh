#! /bin/bash
node bin/download.js
node bin/process.js rawtodaily raw day-events
node bin/process.js reduce day-events month-events
node bin/process.js reduce day-events year-events
