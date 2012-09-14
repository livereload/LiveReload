{ EventEmitter } = require 'events'
RModelSchema = require './schema'

class RModel extends EventEmitter

  constructor: ->
    unless @constructor.name
      throw new Error "R.Model must have a name"

    unless @constructor.schemaObj?.modelClass is @constructor
      @constructor.schemaObj = new RModelSchema(@constructor)

    @attributes     = {}
    @_changedAttrs  = {}
    @_changePending = no

    @initialize()

  initialize: ->

  get: (attr) ->
    @attributes[attr]

  has: (attr) ->
    @attributes[attr]?

  set: (attr, value) ->
    @attributes[attr] = value
    unless @_changedAttrs[attr]
      @_changedAttrs[attr] = yes
      unless @_changePending
        @_changePending = yes
        @universe._internal_modelChanged(this)


  _internal_startProcessingChanges: ->
    @_changePending = no
    attrs = @_changedAttrs
    @_changedAttrs = {}
    return attrs


  # shared instance of R.Universe; initially set to a dummy implementation, will be reset by
  # R.Universe constructor; can be overridden in subclass prototypes or even per instance
  universe: { _internal_modelChanged: (->), destroy: (->) }


module.exports = RModel
