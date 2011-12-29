#! /bin/bash
node bin/download.js
node bin/process.js rawtodaily raw daily
# node bin/process.js reduce daily weekly
node bin/process.js reduce daily monthly
node bin/process.js reduce monthly yearly
