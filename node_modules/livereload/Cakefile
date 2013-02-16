fs   = require 'fs'
Path = require 'path'

task 'upload', ->
  version = JSON.parse(fs.readFileSync('package.json', 'utf8')).version
  tgz     = "livereload-#{version}.tgz"
  url     = "http://download.livereload.com/npm/#{tgz}"

  process.stderr.write "#{url}\n"
  process.stderr.write "\n"
  process.stderr.write "npm pack\n"
  process.stderr.write "s3cmd -P put #{tgz} #{url.replace('http:', 's3:')}\n"
