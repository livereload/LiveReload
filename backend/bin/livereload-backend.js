#! /usr/bin/env node

process.title = "LiveReloadHelper";

require('../lib/livereload').run(process.stdin, process.stdout, process.argv, process.exit);
