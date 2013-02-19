debug = require('debug')('reactive')
types = require('./types')
_     = require 'underscore'


class RAttributeSchema

  constructor: (@modelSchema, @key, options) ->
    @type     = types.resolve(options.type ? 'any')
    @computed = options.computed ? no
    @default  = options.default

    @computeFunc = @modelSchema.modelClass.prototype["compute #{@key}"]
    if !!@computeFunc != !!@computed
      if @computed
        throw new Error "Missing compute func for computed property #{this}"

  toString: ->
    "#{@modelSchema}.attributes.#{@key}"

  preSet: (instance, value) ->
    if @computed then throw new Error "Cannot assign to a computed property #{this}"

    return @type.coerce(value)

  initializeInstance: (instance) ->
    instance.attributes[@key] = @_defaultValue()
    if @computeFunc
      instance.pleasedo "compute #{@key}", =>
        newValue = @computeFunc.call(instance)
        oldValue = instance.attributes[@key]
        if newValue != oldValue
          instance.attributes[@key] = newValue
          instance._changed(@key)

  _defaultValue: ->
    switch typeof @default
      when 'function'
        @default()
      when 'undefined'
        @type.defaultValue()
      else
        @default


class RRegularPropertySchema

  constructor: (@modelSchema, @key) ->
    @getter = null
    @setter = null

  define: (modelClass) ->
    descriptor = {}
    descriptor.get = @getter  if @getter
    descriptor.set = @setter  if @setter
    Object.defineProperty(modelClass.prototype, @key, descriptor)


class RModelSchema

  constructor: (@universe, originalModelClass) ->
    @modelClass = @_createSingletonClass(originalModelClass)

    @attributes = {}
    @autoBlocks = []

    @_handleMagicKeys(@modelClass)


  toString: ->
    "#{@modelClass.name}.schemaObj"


  mixin: (mixinClasses...) ->
    debug "Extending model schema #{@modelClass.name} with mixin #{mixinClasses[0].name}"
    # TODO: create a singleton class if not already done
    for mixinClass in mixinClasses
      @_extendModel(mixinClass)
      @_handleMagicKeys(mixinClass)

  create: (options) ->
    result = new @modelClass(options)
    debug "Created #{result}"
    return result


  _createSingletonClass: (modelClass) ->
    ## This would be a sane way to do this, if Function.name wasn't unassignable
    # singletonClass = (args...) ->
    #   modelClass.apply(this, args)
    # singletonClass.name = modelClass.name

    # so let's do it the insane way
    global.REACTIVE_CLASS_CREATION_HACK = modelClass
    singletonClass = eval("(function(modelClass) { return function #{modelClass.name}() { modelClass.apply(this, arguments); }; })(global.REACTIVE_CLASS_CREATION_HACK);")
    delete global.REACTIVE_CLASS_CREATION_HACK;

    singletonClass.isSingletonClass = yes
    for own k, v of modelClass
      singletonClass[k] = v

    singletonClass.prototype = { constructor: singletonClass }
    singletonClass.prototype.__proto__ = modelClass.prototype

    singletonClass.schemaObj = this
    singletonClass.prototype.universe = @universe

    singletonClass


  _extendModel: (mixinClass) ->
    for own k, v of mixinClass
      if @modelClass.hasOwnProperty(k)
        throw new Error "Key #{JSON.stringify(k)} is already defined on model #{@modelClass.name}, cannot redefine in mixin #{mixinClass.name}"
      @modelClass[k] = v
    for k, v of mixinClass.prototype when !(k is 'schema')
      if @modelClass.prototype.hasOwnProperty(k)
        throw new Error "Prototype key #{JSON.stringify(k)} is already defined on model #{@modelClass.name}, cannot redefine in mixin #{mixinClass.name}"
      @modelClass.prototype[k] = v


  _handleMagicKeys: (mixinClass) ->
    prototype = mixinClass.prototype

    data = _.extend({}, prototype.schema)

    if data._mixins
      mixins = data._mixins; delete data._mixins
      debug "Found mixin metadata in #{mixinClass.name}"

      for [baseClass, mixinClasses] in mixins
        if !Array.isArray(mixinClasses) then mixinClasses = [mixinClasses]
        debug "  baseClass = #{baseClass.name}, mixinClasses = " + (c.name for c in mixinClasses).join(", ")
        @universe.modelSchema(baseClass).mixin mixinClasses...

    for key, options of data
      @attributes[key] =  @_createAttribute(key, options)

    propSchemas = {}
    for key of prototype
      if $ = key.match /^automatically (.*)$/
        value = prototype[key]
        @autoBlocks.push [$[1], value]
      else if $ = key.match /^get (.*)$/
        prop = $[1]
        (propSchemas[prop] or= new RRegularPropertySchema(this, prop)).getter = prototype[key]
      else if $ = key.match /^set (.*)$/
        prop = $[1]
        (propSchemas[prop] or= new RRegularPropertySchema(this, prop)).setter = prototype[key]
    for own key, propSchema of propSchemas
      propSchema.define(@modelClass)


  initializeInstance: (instance) ->
    for own key, attrSchema of @attributes
      attrSchema.initializeInstance(instance)
    for [name, func] in @autoBlocks
      instance.pleasedo name, func.bind(instance)

  _createAttribute: (key, options) ->
    debug "Defining attribute #{@modelClass.name}.#{key}"
    Object.defineProperty @modelClass.prototype, key,
      enumerable: yes
      get: -> @get(key)
      set: (value) -> @set(key, value)
    return new RAttributeSchema(this, key, options)

module.exports = RModelSchema
