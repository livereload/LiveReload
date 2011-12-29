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


exports.DataFileGroups =
  raw:     new DataFileGroup('raw',     'day',    0,  '')
  daily:   new DataFileGroup('daily',   'day',    2)
  weekly:  new DataFileGroup('weekly',  'week',   2)
  monthly: new DataFileGroup('monthly', 'month',  2)
  yearly:  new DataFileGroup('yearly',  'year',   2)
