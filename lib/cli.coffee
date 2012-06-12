Path = require 'path'
fs   = require 'fs'

exports.run = (argv) ->
  options = require('dreamopt') [
    'Mode selection:'
    '  -w, --watch  Watch the given directory'
    'Directories:'
    '  -d, --directory DIR  Operate on the given directory #list #var(dirs)'
  ]
  console.log JSON.stringify(options)

  if options.dirs.length is 0
    process.stderr.write "At least one directory is required (for now)."
    process.exit 2

  dirs = for dir in options.dirs
    Path.resolve(dir)

  if options.watch
    console.log "TODO: watch " + dirs.join(", ")

