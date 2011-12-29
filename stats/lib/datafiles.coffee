fs    = require 'fs'
Path  = require 'path'


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

  readSync:  -> JSON.parse(fs.readFileSync(@path))

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

for [ category, levels ] in [['events', 2], ['users', 1]]
  for granularity in require('./granularities').all
    name = "#{granularity}-#{category}"
    DataFileGroups[name] = new DataFileGroup(name, granularity, levels)
