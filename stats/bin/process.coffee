require 'sugar'

fs    = require 'fs'
Path  = require 'path'
util  = require 'util'

{DataFileGroups} = require '../lib/datafiles'
filecrunching    = require '../lib/filecrunching'

processors = fs.readdirSync(Path.join(__dirname, '../lib/processing')).filter(/\.js$/).map((s) -> s.replace('.js', ''))
groups     = Object.keys(DataFileGroups)

options = require('dreamopt') [
  "Usage: node bin/process.js #{processors.join('|')} #{groups.join('|')} #{groups.join('|')}"

  "processor            A processor to run (a module under lib/processing)  #required"
  "input                Source file group to process                        #required"
  "output               Destination file group to write to                  #required"

  "Options affecting which input files are processed:"
  "-s, --since DATE     On or after this date   #date"
  "-u, --until DATE     Before or on this date  #date"
  "-f, --force          Force reprocessing of all files"

  "Output verbosity options:"
  "--show-sources       Show source files for each output file  #var(showSources)"

  "Generic options:"
], {
  date: (value, options, optionName) ->
    unless value.match /^\d{4}-\d{2}-\d{2}$/
      throw new Error("Invalid date for option #{optionName}")
    value
}

die = (message) ->
  util.debug message
  process.exit 1

processor = require "../lib/processing/#{options.processor}"
input     = DataFileGroups[options.input]  or die "Invalid input: #{options.input}"
output    = DataFileGroups[options.output] or die "Invalid output: #{options.input}"

filecrunching.run options, input, output, processor
