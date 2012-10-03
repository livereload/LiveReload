fs   = require 'fs'
Path = require 'path'


class FSFile
  constructor: (@relpath, @stats) ->

  toString: ->
    @relpath


module.exports =
class FSTree

  constructor: (@root) ->
    @files = []
    @errors = []

  scan: (callback) ->
    @_walk(@root, '', callback)

  getAllPaths: ->
    (file.relpath for file in @files).sort()

  findMatchingPaths: (list) ->
    (file.relpath for file in @files when list.matches(file.relpath)).sort()


  _addError: (path, err) ->
    @errors.push { path, err }

  _addFile: (relpath, stats) ->
    @files.push new FSFile(relpath, stats)

  _walk: (path, relpath, autocb) ->
    await fs.lstat path, defer(err, stats)
    return @_addError(path, err) if err

    if stats.isFile()
      @_addFile relpath, stats
    else if stats.isDirectory()
      await fs.readdir path, defer(err, files)
      return @_addError(path, err) if err

      for file in files
        await @_walk Path.join(path, file), Path.join(relpath, file), defer()
