debug = require('debug')('vfs:test')
fs    = require 'fs'
Path  = require 'path'

{PlaPath} = require './paths'

{ EventEmitter } = require 'events'


class Monitor extends EventEmitter

  constructor: (@vfs, @path) ->
    @vfs.monitors.push this

  close: ->
    if (index = @vfs.monitors.indexOf this) >= 0
      @vfs.monitors.splice index, 1

  includes: (candidate) ->
    (candidate == @path) or (candidate.substr(0, @path.length + 1) == @path + '/')

class TestVFS

  constructor: ->
    @files = {}
    @monitors = []


  # testing API

  get: (path) ->
    @files[path]

  put: (path, body) ->
    @files[path] = body
    @changed path

  changed: (path) ->
    for monitor in @monitors
      if monitor.includes(path)
        monitor.emit 'change', path


  # public API

  normalize: (path) ->
    fs.normalize(path)

  exists: (path, callback) ->
    @files.hasOwnProperty(path)

  writeFile: (path, data, callback) ->
    process.nextTick =>
      @put path, data
      callback(null)

  readFile: (path, encoding, callback) ->
    process.nextTick =>
      callback null, @files[path]

  watch: (path) ->
    new Monitor(this, path)

  isSubpath: (superpath, subpath) ->
    subpath = "#{subpath}/" unless subpath[subpath.length - 1] is '/'
    return (subpath.length >= superpath.length) and (subpath.substr(0, superpath.length) == superpath)

  findFilesMatchingSuffixInSubtree: (root, suffix, bestSubtree, callback) ->
    suffix = PlaPath.normalize(suffix)

    name = Path.basename(suffix)

    bestScore = 0

    allMatches =
      for own path, content of @files
        debug "findFilesMatchingSuffixInSubtree considering: root = %j, path = %j, PlaPath.isSubpath = %j", root, path, PlaPath.isSubpath(path, root)

        continue unless PlaPath.isSubpath(path, root)
        path = PlaPath.normalize path.substr(root.length)

        continue unless Path.basename(path) is name
        score = PlaPath.numberOfMatchingTrailingComponents(path, suffix)
        score += 0.5 if bestSubtree && PlaPath.isSubpath(path, bestSubtree)

        bestScore = score if score > bestScore

        debug "findFilesMatchingSuffixInSubtree match: path = %j, score = %j", path, score

        { path, score }

    bestMatches = (match for match in allMatches when match.score is bestScore)

    bestMatch = if bestMatches.length is 1 then bestMatches[0] else null

    process.nextTick ->
      callback null, { allMatches, bestMatches, bestMatch }


module.exports = TestVFS

