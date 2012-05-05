
module.exports = class WhistlingArray extends Array

  constructor: (@source, initialValue) ->
    super()
    Array::push.apply(this, initialValue)

  push: (args...) ->
    result = super(args...)
    @source.fire()
    return result

  pop: (args...) ->
    result = super(args...)
    @source.fire()
    return result

  shift: (args...) ->
    result = super(args...)
    @source.fire()
    return result

  unshift: (args...) ->
    result = super(args...)
    @source.fire()
    return result

  splice: (args...) ->
    result = super(args...)
    @source.fire()
    return result

  set: (index, value) ->
    @[index] = value
    @source.fire()
    return value

  toJSON: -> @slice(0)

  toString: -> ('' + el for el in this).join(',')
