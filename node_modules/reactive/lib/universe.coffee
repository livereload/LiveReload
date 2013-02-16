debug = require('debug')('reactive')
{ EventEmitter } = require 'events'
RModel           = require './model'
RModelSchema     = require './schema'


class RUniverse extends EventEmitter

  constructor: ->
    @_changedModels = []
    @_scheduled = no
    @_completionFuncs = []
    @_blocks = []
    @_blocksById = {}
    @_nextOrdinal = {}

    @_modelSchemas = {}

    @currentCollector = null

    @_processPendingChanges = @_processPendingChanges.bind(@)

    if RModel.prototype.universe
      RModel.prototype.universe.destroy()
    RModel.prototype.universe = this

  destroy: ->
    if RModel.prototype.universe is this
      RModel.prototype.universe = null


  then: (func) ->
    @_completionFuncs.push func
    @_scheduleChangeProcessing()


  uniqueId: (className, detail) ->
    detail = if detail then ('_' + detail).replace(/[^0-9a-zA-Z]+/g, '_') else ''

    @_nextOrdinal[className] or= 0
    ordinal = @_nextOrdinal[className]++

    "#{className}#{ordinal}#{detail}"


  dependency: (model, attribute) ->
    @currentCollector?.dependency(model, attribute)


  mixin: (modelClass, mixinClasses...) ->
    @modelSchema(modelClass).mixin(mixinClasses...)

  create: (modelClass, options={}) ->
    @modelSchema(modelClass).create(options)

  modelSchema: (modelClass) ->
    unless modelClass.name
      throw new Error "R.Universe require model classes to have a .name"
    @_modelSchemas[modelClass.name] or= new RModelSchema(this, modelClass)

  _internal_modelChanged: (model) ->
    # debug "Model change pending: #{model}"
    @_changedModels.push(model)
    @_scheduleChangeProcessing()

  _internal_scheduleBlock: (block) ->
    bid = block._id
    unless @_blocksById.hasOwnProperty(bid)
      @_blocksById[bid] = yes
      @_blocks.push block
    @_scheduleChangeProcessing()

  _processPendingChanges: ->
    while (@_changedModels.length > 0) or (@_blocks.length > 0) or (@_completionFuncs.length > 0)
      while model = @_changedModels.shift()
        attrs = model._internal_startProcessingChanges()
        for attr, value of attrs
          debug "Change: #{model}.#{attr} is now #{model.get(attr)}"
          @emit 'change', model, attr

          for subscriber in model.subscribersTo(attr)
            @_internal_scheduleBlock(subscriber)

      while block = @_blocks.shift()
        delete @_blocksById[block._id]
        block.execute()
        break if (@_changedModels.length > 0)

      while func = @_completionFuncs.shift()
        func()
        break if (@_changedModels.length > 0) or (@_blocks.length > 0)

    @_scheduled = no


  _scheduleChangeProcessing: ->
    unless @_scheduled
      process.nextTick @_processPendingChanges
      @_scheduled = yes


module.exports = RUniverse
