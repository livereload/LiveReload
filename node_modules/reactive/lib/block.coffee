debug = require('debug')('reactive')


class RBlock

  constructor: (@ownerModel, name, @func) ->
    universe = @ownerModel.universe

    @_id = @ownerModel._id + "_" + universe.uniqueId("B", name or func.name)
    # debug "Created block #{this}"

    @ownerModel._blocks.push this
    @_dependencies = {}

    universe._internal_scheduleBlock(this)

  toString: -> @_id


  dispose: ->
    for own dummy, model of @_dependencies
      model.unsubscribe(this)

  execute: ->
    debug "Executing block #{this}"

    for own dummy, model of @_dependencies
      model.unsubscribe(this)

    universe = @ownerModel.universe
    prevCollector = universe.currentCollector
    universe.currentCollector = this
    try
      rv = @func()
    finally
      universe.currentCollector = prevCollector
    return rv

  dependency: (model, attribute) ->
    debug "#{this} depends on #{model}.#{attribute}"
    model.subscribe(this, attribute)
    @_dependencies[model._id] = model


module.exports = RBlock
