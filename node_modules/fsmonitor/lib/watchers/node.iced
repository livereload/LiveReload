debug = require('debug')('fsmonitor')
fs    = require 'fs'
Path  = require 'path'

{ EventEmitter } = require 'events'


module.exports =
class NodeWatcher extends EventEmitter

  constructor: (@root) ->
    @_watchers = {}
    @_broken = {}

  close: ->
    for own relpath, watcher of @watchers
      watcher.close()
    @_watchers = null

  addFolder: (relpath) ->
    @_watchers[relpath] or= do =>
      try
        watcher = fs.watch(Path.join(@root, relpath))
      catch error
        return @_addFolderError(relpath, error)

      watcher.on 'change', (event, filename) =>
        debug "fs.watch incoming change: event = %j, filename = %j", event, filename
        @emit 'change', relpath, filename, no

      watcher.on 'error', (error) =>
        return @_addFolderError(relpath, error)

      watcher

  removeFolder: (relpath) ->
    if @_watchers.hasOwnProperty(relpath)
      @_watchers[relpath].close()
      delete @_watchers[relpath]
      delete @_broken[relpath]


  _addBroken: (broken) ->
    @_broken[broken.relpath] = broken
    debug "broken folder: #{JSON.stringify broken, null, 2}\n"

  _addFolderError: (relpath, error) ->
    fullPath = Path.join(@root, relpath)

    # Windows likes to throw EPERM error when the monitored folder is deleted; ignore it
    await fs.exists(fullPath, defer(exists))
    return unless exists

    broken =
      code:     'EFAIL'
      message:  "Error monitoring folder '[path]'"
      error:    error
      relpath:  relpath
      fullPath: fullPath
      expected: no

    if error.code is 'EPERM'
      broken.code = 'EPERM'
      broken.expected = yes
      broken.message = "No permission to access folder '[path]'"

    @_addBroken broken

    # unless broken.expected
    #   @emit 'error', broken.error, broken

    undefined
