fs    = require 'fs'
Path  = require 'path'

Hierarchy = require './hierarchy'


outputDir = Path.join(__dirname, '../data')


class DataFileGroup

  constructor: (@subdir, @granularity, @levels, @suffix = '-' + @subdir) ->
    @path     = Path.join(outputDir, @subdir)
    @fsSuffix = "#{@suffix}.json"
    @regexp   = RegExp(RegExp.escape(@fsSuffix) + '$')

  idToFileName: (id)   -> id + @fsSuffix

  fileNameToId: (name) -> name.replace(@regexp, '')

  allFiles: ->
    for fileName in fs.readdirSync(@path) when fileName.match(@regexp)
      new DataFile(this, Path.join(@path, fileName), @fileNameToId(fileName))

  file: (id) ->
    new DataFile(this, Path.join(@path, @idToFileName(id)), id)

  getDirectoryPath: (create=no) ->
    try
      fs.mkdirSync(@path, )


class DataFile
  constructor: (@group, @path, @id) ->
    @name = Path.basename(@path)

  exists:    -> Path.existsSync(@path)

  readSync:  ->
    result = JSON.parse(fs.readFileSync(@path))
    if @group.levels > 0
      Hierarchy(result, @group.levels)
    else
      result

  writeSync: (data) ->
    unless Path.existsSync(Path.dirname(@path))
      fs.mkdirSync(Path.dirname(@path), 0770)
    fs.writeFileSync(@path, JSON.stringify(data, null, 2))

  timestamp: ->
    try
      fs.statSync(@path).mtime.getTime()
    catch e
      0


exports.DataFileGroups = DataFileGroups =
  raw:     new DataFileGroup('raw',     'day',    0,  '')

CATEGORIES = [
  ['events', 2]
  ['events-cum', 2]
  ['users', 1]
  ['users-temp', 1]
]

do ->
  for [ category, levels ] in CATEGORIES
    for granularity in require('./granularities').all
      name = "#{granularity}-#{category}"
      DataFileGroups[name] = new DataFileGroup(name, granularity, levels)
