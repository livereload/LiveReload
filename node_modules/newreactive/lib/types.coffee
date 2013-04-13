
class ArrayType
  isTypeDescriptor: yes

  constructor: (@elemType) ->

  toString: ->
    "{ array: #{@elemType} }"

  defaultValue: -> []

  coerce: (value) ->
    unless Array.isArray(value)
      throw new Error("Value is not an array: " + JSON.stringify(value))
    if @elemType is StdTypes.any
      value.slice(0)
    else
      (@elemType.coerce(elem) for elem in value)


class ObjectType
  isTypeDescriptor: yes

  constructor: (@class) ->
    if !@class.name then throw new Error "Only classes with a .name can be used for type checking"

  toString: ->
    "{ object: #{@class.name} }"

  coerce: (value) ->
    if value?
      unless typeof value is 'object'
        throw new Error "Invalid #{typeof value} value, expected #{@class.name}"
      unless value instanceof @class
        throw new Error "Invalid #{value.constructor.name or 'object'} value, expected #{@class.name}"
    value

  defaultValue: -> null  # TODO: deal with nullability


StdTypes =
  any:
    isTypeDescriptor: yes
    coerce: (value) ->
      value
    toString: ->
      'any'
    defaultValue: -> null

  string:
    isTypeDescriptor: yes
    coerce: (value) ->
      if value?
        "#{value}"
      else
        null
    toString: ->
      'string'
    defaultValue: -> ''

  int:
    isTypeDescriptor: yes
    coerce: (value) ->
      ~~value
    toString: ->
      'int'
    defaultValue: -> 0

  number:
    isTypeDescriptor: yes
    coerce: (value) ->
      +value
    toString: ->
      'number'
    defaultValue: -> 0

  boolean:
    isTypeDescriptor: yes
    coerce: (value) ->
      !!value
    toString: ->
      'boolean'
    defaultValue: -> no

StdTypes.array = new ArrayType(StdTypes.any)


exports.resolve = resolve = (type) ->
  if !type?
    StdTypes.any
  else if type.isTypeDescriptor
    type
  else
    switch typeof type
      when 'string'
        StdTypes[type] or throw new Error "Unknown type name #{type}"
      when 'object'
        if type.constructor is Object
          keys = Object.keys(type)
          if (keys.length is 1) and (keys[0] is 'array')
            new ArrayType(resolve(type.array))
          else if (keys.length is 1) and (keys[0] is 'object')
            new ObjectType(type.object)
          else
            throw new Error "Unsupported type declaration #{type}"
        else
          throw new Error "Unsupported type declaration #{type}"
      when 'function'
        if type is String
          StdTypes.string
        else if type is Array
          StdTypes.array
        else if type is Boolean
          StdTypes.boolean
        else if type is Number
          StdTypes.number
        else if type is Object
          StdTypes.any
        else
          new ObjectType(type)


exports.coerce = (value, type) ->
  resolve(type).coerce(value)
