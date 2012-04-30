{ EventEmitter } = require 'events'

WhistlingArray = require './lib/array'


class Entity extends EventEmitter

  constructor: ->
    @__eid = "E#{R.nextEntityId++}"

  __defprop: (name, initialValue) ->
    reactive = new Var(this, name, "_#{name}", initialValue)

    Object.defineProperty this, name,
      get: -> reactive.get()
      set: (newValue) -> reactive.set(newValue)


class Context
  constructor: (@func) ->
    @id = "C#{R.nextContextId++}"
    @dirty = yes
    @_validate()

  dependsOn: (entity) ->
    entity.on 'change', @invalidate.bind(@)

  invalidate: ->
    return if @dirty
    @dirty = yes
    R.enqueue @_validate.bind(@)

  _validate: ->
    return unless @dirty
    @dirty = no
    R.withContext this, @func


class Property
  constructor: (@entity, @name) ->
    while @entity.container?
      @entity = @entity.container

  infect: ->
    R.context?.dependsOn(@entity)

  fire: ->
    @entity.emit 'change'


class Var extends Property
  constructor: (@holder, name, @field, initialValue) ->
    super(@holder, name)
    if initialValue && initialValue.constructor is Array
      initialValue = new WhistlingArray(this, initialValue)
    @holder[@field] = initialValue

  get: ->
    @infect()
    @holder[@field]

  set: (newValue) ->
    @holder[@field] = newValue
    @fire()


module.exports = R =
  Entity: Entity

  nextContextId: 1
  nextEntityId: 1

  context: null

  queue: []

  autoflush: yes

  enqueue: (func) ->
    if R.autoflush && R.queue.length is 0
      process.nextTick R.flush
    R.queue.push func

  flush: ->
    while R.queue.length > 0
      thisBatch = R.queue; R.queue = []
      for func in thisBatch
        func()
    return

  withContext: (context, func) ->
    oldContext = R.context; R.context = context
    try
      result = func()
    finally
      R.context = oldContext
    return result

  run: (func) ->
    new Context(func)



# project.name

# R.ref this, 'selectedProject', null, =>
#   @selectedProject = null
