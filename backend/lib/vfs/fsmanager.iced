
FSHive = require './fshive'

module.exports = class FSManager

  constructor: ->
    @_nextHiveId = 1
    @_hives = {}

  createHive: (path) ->
    hive = new FSHive("H#{@_nextHiveId++}", path)
    @_hives[hive.id] = hive
    hive.on 'dispose', =>
      delete @_hives[hive.id]
    return hive

  handleFSChangeEvent: (event, callback) ->
    if hive = @_hives[event.id]
      hive.handleFSChangeEvent(event, callback)
    else
      callback(new Error("Hive ID '#{event.id}' not found"));
