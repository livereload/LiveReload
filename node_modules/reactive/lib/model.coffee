{ EventEmitter } = require 'events'
RBlock = require './block'

class RModel extends EventEmitter

  constructor: (options) ->
    unless @constructor.name
      throw new Error "R.Model must have a name"

    unless @constructor.isSingletonClass
      throw new Error "R.Model subclass #{@constructor.name} must be instantiated via R.Universe.create()"

    @_id = @universe.uniqueId(@constructor.name)

    @attributes     = {}
    @_changedAttrs  = {}
    @_changePending = no

    @_blocks = []  # will be populated by RBlock

    # format: attr1, subscriber1, attr2, subscriber2, ...
    @_subscribers = []

    schema = @constructor.schemaObj
    schema.initializeInstance(this)

    for own k, v of options
      if schema.attributes.hasOwnProperty(k)
        @set(k, v)

    @initialize(options)

  toString: -> @_id

  initialize: (options) ->

  dispose: ->
    for block in @_blocks
      block.dispose()
    @_blocks = []

  pleasedo: (name, func) ->
    new RBlock this, name, func

  get: (attr) ->
    @universe.dependency(this, attr)
    @attributes[attr]

  has: (attr) ->
    @attributes[attr]?

  set: (attr, value) ->
    unless attrSchema = @constructor.schemaObj.attributes[attr]
      throw new Error "Unknown attribute #{@constructor.name}.#{attr}"
    value = attrSchema.preSet(this, value)

    if @attributes[attr] != value
      @attributes[attr] = value
      @_changed(attr)

  _changed: (attr) ->
    unless @_changedAttrs[attr]
      @_changedAttrs[attr] = yes
      unless @_changePending
        @_changePending = yes
        @universe._internal_modelChanged(this)


  subscribe: (subscriber, attribute) ->
    @_subscribers.push subscriber, attribute

  unsubscribe: (subscriber) ->
    subscribers = @_subscribers
    index = 0
    while (index = subscribers.indexOf(subscriber, index)) >= 0
      subscribers.splice index, 2

  subscribersTo: (attribute) ->
    subscribers = @_subscribers
    result = []
    index  = -1
    while (index = subscribers.indexOf(attribute, index + 1)) >= 0
      result.push subscribers[index - 1]
    return result


  _internal_startProcessingChanges: ->
    @_changePending = no
    attrs = @_changedAttrs
    @_changedAttrs = {}
    return attrs


module.exports = RModel
