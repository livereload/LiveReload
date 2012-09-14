{ EventEmitter } = require 'events'
RModel           = require './model'


class RUniverse extends EventEmitter

  constructor: ->
    @_changedModels = []
    @_scheduled = no
    @_completionFuncs = []

    @_processPendingChanges = @_processPendingChanges.bind(@)

    if RModel.prototype.universe
      RModel.prototype.universe.destroy()
    RModel.prototype.universe = this

  destroy: ->
    if RModel.prototype.universe is this
      RModel.prototype.universe = null


  then: (func) ->
    @_completionFuncs.push func


  _internal_modelChanged: (model) ->
    @_changedModels.push(model)
    @_scheduleChangeProcessing()


  _processPendingChanges: ->
    @_scheduled = no
    while model = @_changedModels.shift()
      attrs = model._internal_startProcessingChanges()
      for attr, value of attrs
        @emit 'change', model, attr

    while func = @_completionFuncs.shift()
      func()


  _scheduleChangeProcessing: ->
    unless @_scheduled
      process.nextTick @_processPendingChanges
      @_scheduled = yes


module.exports = RUniverse
