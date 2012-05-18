Path = require 'path'
fs   = require 'fs'

{ EventEmitter } = require 'events'

RelPathList = require './relpathlist'


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


createLineStream = (stream) ->
  result = new EventEmitter()
  leftover = ''

  stream.setEncoding 'utf-8'
  stream.on 'data', (chunk) ->
    lines = (leftover + chunk).split "\n"
    leftover = lines.pop()

    for line in lines
      result.emit 'line', line

    return

  stream.on 'end', ->
    if leftover
      result.emit 'line', leftover
    result.emit 'end'

  result


createStdinFileStream = ->
  result = new EventEmitter()

  createLineStream(process.stdin).on 'line', (line) ->
    result.emit 'file', line

  result.resume = -> process.stdin.resume()

  return result


createTreeFileStream = (rootPath) ->
  result = new EventEmitter()

  scan = (folder) ->
    fs.readdir folder, (err, files) ->
      if err
        result.emit 'error', err
      else
        for file in files
          file = Path.join(folder, file)
          do (file) ->
            fs.stat file, (err, stats) ->
              if err
                result.emit 'error', err
              else if stats.isDirectory()
                scan file
              else
                result.emit 'file', file

  result.resume = -> scan rootPath

  return result


module.exports = (argv) ->
  usage() if argv.length < 2 or '--help' in argv

  verbose = no
  argv = argv.filter (arg) ->
    if arg in ['-v', '--verbose']
      verbose = yes; return no
    return yes

  rootPath = argv.shift()
  if rootPath is '-'
    enumerator = createStdinFileStream()
  else
    unless fs.statSync(rootPath)
      process.stderr.write "Root path does not exist: #{rootPath}\n"
      process.exit 2
    enumerator = createTreeFileStream(rootPath)

  pathList = RelPathList.parse(argv)
  process.stderr.write "Path List: #{pathList}\n" if verbose

  enumerator.on 'file', (path) ->
    # process.stderr.write "Checking: #{path}\n"
    if pathList.matches(path)
      process.stdout.write "#{path}\n"

  enumerator.on 'error', (err) ->
    process.stderr.write "Error: #{err.stack || err.message || err}\n"
    process.exit 1

  enumerator.resume()
