{ EventEmitter } = require 'events'

WhistlingArray = require './lib/array'


# interface Dependable:
#    __uid
#    addListener(event, handler)
#    removeListener(event, handler)
#    event 'change'

class Entity extends EventEmitter

  constructor: (uidSuffix) ->
    R.hook(this, uidSuffix)

  __addprop: (name, reactive) ->
    Object.defineProperty this, name,
      get: -> reactive.get()
      set: (newValue) -> reactive.set(newValue)
    return reactive

  __defprop: (name, initialValue, options={}) ->
    options.initialValue = initialValue
    @__addprop name, new Var(this, name, options)

  __deriveprop: (name, options) ->
    if typeof options is 'function'
      options = { compute: options }

    @__addprop name, new ComputedVar(this, name, options)


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


class Property extends EventEmitter
  constructor: (@entity, @name) ->
    @__uid = R.uniqueId 'P', name, @entity.__uid
    while @entity.container?
      @entity = @entity.container

  infect: ->
    R.context?.dependsOn(this)

  fire: ->
    LR.log.fyi "R.propchange: #{@name} of #{@entity.__uid}"
    @emit 'change'
    @entity.emit 'propchange', @name
    @entity.emit "#{@name}.change"


class Var extends Property
  constructor: (@holder, name, { initialValue, set, onchange }) ->
    super(@holder, name)

    if initialValue && initialValue.constructor is Array
      initialValue = new WhistlingArray(this, initialValue)

    @_setter = set || @setInternally

    @on 'change', onchange  if onchange

    @holder["#{@name}$$"] = this
    @holder["_raw_#{@name}"] = initialValue

  peek: ->
    @holder["_raw_#{@name}"]

  get: ->
    @infect()
    @peek()

  setInternally: (newValue) ->
    LR.log.fyi "#{@name}.setInternally: old = #{@peek()}, new = #{newValue}"
    unless @peek() == newValue
      @holder["_raw_#{@name}"] = newValue
      @fire()

  set: (newValue) ->
    @_setter.call(this, newValue, this)


class ComputedVar extends Var

  constructor: (holder, name, options) ->
    options.set ||= => throw new Error("#{@name} of #{@entity.__uid} is not settable")

    super(holder, name, options)

    R.runNamed "#{@entity.__uid}_compute_#{@name}", =>
      @setInternally options.compute()



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

  hook: (object, uidSuffix) ->
    object.__uid = R.uniqueId object.constructor.name || 'E', uidSuffix

    # a tinsy bit of magic
    for k, v of object
      if k.match /^automatically /
        do (k, v) ->
          process.nextTick ->
            R.runNamed object.__uid + "_" + k.substr('automatically '.length), v.bind(object)

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
