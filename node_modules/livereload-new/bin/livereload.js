#!/usr/bin/env node
process.env.DEBUG || (process.env.DEBUG = 'livereload:*')
require('../lib/main').run(process.argv.slice(2));
