debug = require('debug')('vfs:local')
fs = require 'fs'
Path = require 'path'

{ EventEmitter } = require 'events'

class Monitor extends EventEmitter

  constructor: (@path) ->

  close: ->


class LocalVFS

  writeFile: (path, data, callback) ->
    fs.writeFile path, data, callback

  readFile: (path, encoding, callback) ->
    fs.readFile path, encoding, callback

  watch: (path) ->
    new Monitor(path)

  isSubpath: (superpath, subpath) ->
    subpath = "#{subpath}/" unless subpath[subpath.length - 1] is '/'
    return (subpath.length >= superpath.length) and (subpath.substr(0, superpath.length) == superpath)

  findFilesMatchingSuffixInSubtree: (root, suffix, bestSubtree, callback) ->
    process.nextTick ->
      callback null, { allMatches: [], bestMatches: [], bestMatch: null }

module.exports = new LocalVFS()  # the one and only copy
module.exports.LocalVFS = LocalVFS
