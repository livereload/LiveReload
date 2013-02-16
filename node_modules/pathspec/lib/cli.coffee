Path = require 'path'
fs   = require 'fs'

{ EventEmitter } = require 'events'

RelPathList = require './relpathlist'
TreeStream  = require './treestream'


usage = ->
  process.stderr.write "" +
    "Similar to find(1), but uses pathspec.js for filtering.\n\n" +
    "Usage: pathspec-find [-v|--verbose] /path/to/dir spec1 spec2...\n" +
    "   or: pathspec-find [-v|--verbose] - spec1 spec2...\n\n" +
    "The first argument is the folder to look in. Pass a single dash ('-') to read the list of\n" +
    "files from stdin, one path per line.\n\n" +
    "The remaining arguments are .gitignore-style masks. At least one is required.\n\n" +
    "Examples:\n" +
    "    pathspec-find . '*.json'\n" +
    "    find . | pathspec-find - '*.json' '!excluded/folder'\n\n" +
    "(C) 2012, Andrey Tarantsov -- https://github.com/andreyvit/pathspec.js\n\n"
  process.exit 41


createLineStream = require './util/linestream'


createStdinFileStream = (list) ->
  result = new EventEmitter()

  stream = createLineStream(process.stdin)
  stream.on 'line', (line) ->
    if list.matches(line)
      result.emit 'file', line
  stream.on 'end', ->
    result.emit 'end'

  process.stdin.resume()
  return result


module.exports = (argv) ->
  usage() if argv.length < 2 or '--help' in argv

  verbose = no
  absolute = no
  argv = argv.filter (arg) ->
    if arg in ['-v', '--verbose']
      verbose = yes; return no
    if arg in ['-a', '--absolute']
      absolute = yes; return no
    return yes

  rootPath = argv.shift()

  list = RelPathList.parse(argv)
  process.stderr.write "Path List: #{list}\n" if verbose

  if rootPath is '-'
    stream = createStdinFileStream(list)
  else
    unless fs.statSync(rootPath)
      process.stderr.write "Root path does not exist: #{rootPath}\n"
      process.exit 2
    stream = new TreeStream(list).visit(rootPath)

  stream.on 'file', (path, absPath) ->
    o = (if absolute then absPath else path)
    process.stdout.write "#{o}\n"

  if verbose
    stream.on 'folder', (path, absPath) ->
      o = (if absolute then absPath else path)
      process.stderr.write "Folder: #{o}/\n"

  stream.on 'error', (err) ->
    process.stderr.write "Error: #{err.stack || err.message || err}\n"
    process.exit 1
