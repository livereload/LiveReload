{ EventEmitter } = require 'events'

FSTree = require './tree'
Watcher = require './watchers/node'


# Watches the given subtree for changes and emits a `change` event when any files or folders are
# modified.
module.exports =
class FSMonitor extends EventEmitter

  constructor: (@root, @filter, options) ->
    @tree = new FSTree(@root, @filter)
    @tree.once 'complete', @_finishInitialization.bind(@)
    @tree.on 'change', @_processChange.bind(@)

  close: ->
    @watcher?.close()
    @watcher = null

  _finishInitialization: ->
    @watcher = new Watcher(@root)
    @watcher.on 'change', (folder, filename, recursive) =>
      @tree.update folder, filename, recursive

    for folder in @tree.allFolders
      @watcher.addFolder folder

    @emit 'complete'

  _processChange: (change) ->
    for folder in change.addedFolders
      @watcher.addFolder folder
    for folder in change.removedFolders
      @watcher.removeFolder folder
    @emit 'change', change
