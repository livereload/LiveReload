{ EventEmitter } = require 'events'

WhistlingArray = require './lib/array'


# interface Dependable:
#    __uid
#    addListener(event, handler)
#    removeListener(event, handler)
#    event 'change'


class Entity extends EventEmitter

  constructor: (uidSuffix) ->
    @__uid = R.uniqueId @constructor.name || 'E', uidSuffix

    # a tinsy bit of magic
    for k, v of this
      if k.match /^automatically /
        do (k, v) =>
          process.nextTick =>
            R.runNamed @__uid + "_" + k.substr('automatically '.length), v.bind(@)

  __defprop: (name, initialValue) ->
    reactive = new Var(this, name, "_#{name}", initialValue)

    Object.defineProperty this, name,
      get: -> reactive.get()
      set: (newValue) -> reactive.set(newValue)

    return reactive

  __deriveprop: (name, func) ->
    reactive = @__defprop name, undefined
    reactive.propGroup = new PropertyGroup(name)
    R.runNamed "#{@__uid}_compute_#{name}", =>
      @[name] = func()


class PropertyGroup extends EventEmitter

  constructor: (name) ->
    @__uid = R.uniqueId 'PG', name


class Context
  constructor: (@func, name) ->
    @id = R.uniqueId 'C', name || @func.name
    @dirty = yes
    @_depedencies = {}
    @_prevdep = undefined
    @invalidate = @invalidate.bind(@)

    @_validate()

  dependsOn: (dependable) ->
    return unless @_prevdep

    unless dependable.__uid of @_depedencies
      @_depedencies[dependable.__uid] = dependable

      if dependable.__uid of @_prevdep
        @_prevdep[dependable.__uid] = undefined
      else
        dependable.addListener 'change', @invalidate

  invalidate: ->
    return if @dirty
    @dirty = yes
    R.enqueue @_validate.bind(@)

  _validate: ->
    return unless @dirty
    @dirty = no

    @_prevdep = @_depedencies
    @_depedencies = {}

    LR.log.fyi "R.run: #{@id}"
    R.withContext this, @func

    for own _, entity of @_prevdep when entity
      entity.removeListener 'change', @invalidate
    @_prevdep = undefined


class Property
  constructor: (@entity, @name) ->
    while @entity.container?
      @entity = @entity.container

  dependable: -> @propGroup || @entity

  infect: ->
    R.context?.dependsOn(@dependable())

  fire: ->
    LR.log.fyi "R.propchange: #{@name} of #{@entity.__uid}"
    @dependable().emit 'change'


class Var extends Property
  constructor: (@holder, name, @field, initialValue) ->
    super(@holder, name)
    if initialValue && initialValue.constructor is Array
      initialValue = new WhistlingArray(this, initialValue)
    @holder[@field] = initialValue

  peek: ->
    @holder[@field]

  get: ->
    @infect()
    @peek()

  set: (newValue) ->
    unless @peek() == newValue
      @holder[@field] = newValue
      @fire()


module.exports = R =
  Entity: Entity

  nextUniqueId: {}

  uniqueId: (prefix, suffix) ->
    if !prefix || typeof(prefix) != 'string'
      throw new Error("R.uniqueId(prefix, suffix) has been called with a non-string prefix of type #{typeof prefix}")
    if suffix
      if typeof(suffix) != 'string'
        throw new Error("R.uniqueId(prefix, suffix) has been called with a non-string suffix of type #{typeof suffix}")

      suffix = suffix.replace(/[\s_-]+/g, '_')

    R.nextUniqueId[prefix] ||= 1
    return "#{prefix}#{R.nextUniqueId[prefix]++}" + if suffix then "_#{suffix}" else ''

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

  runNamed: (name, func) ->
    new Context(func, name)



# project.name

# R.ref this, 'selectedProject', null, =>
#   @selectedProject = null
