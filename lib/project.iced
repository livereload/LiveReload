{ EventEmitter } = require 'events'

class Project extends EventEmitter

  constructor: (@vfs, @path) ->

  startMonitoring: ->
    unless @monitor
      @monitor = @vfs.watch(@path)
      @monitor.on 'change', (path) =>
        @emit 'change', path

  stopMonitoring: ->
    @monitor?.close()
    @monitor = null


module.exports = Project

