fs   = require 'fs'
Path = require 'path'

{ EventEmitter } = require 'events'

module.exports =
class FSSubtree extends EventEmitter

  # stub implementation

  constructor: (@path) ->
    @watcher = fs.watch(@path)
    @watcher.on 'change', (event, filename) =>
      @emit 'change', @path, event, filename

    console.log "Watching #{@path}..."

  close: ->
    @watcher.close()
