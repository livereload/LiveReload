debug = require('debug')('fsmonitor')
fs    = require 'fs'
Path  = require 'path'

{ EventEmitter } = require 'events'


module.exports =
class NodeWatcher extends EventEmitter

  constructor: (@root) ->
    @_watchers = {}

  close: ->
    for own relpath, watcher of @watchers
      watcher.close()
    @_watchers = null

  addFolder: (relpath) ->
    @_watchers[relpath] or= do =>
      watcher = fs.watch(Path.join(@root, relpath))
      watcher.on 'change', (event, filename) =>
        debug "fs.watch incoming change: event = %j, filename = %j", event, filename
        @emit 'change', relpath, filename, no
      watcher

  removeFolder: (relpath) ->
    if @_watchers.hasOwnProperty(relpath)
      @_watchers[relpath].close()
      delete @_watchers[relpath]
