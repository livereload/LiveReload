debug = require('debug')('reactive')

class RModelSchema

  constructor: (@modelClass) ->
    @attributes = {}

    data = @modelClass.prototype.schema ? {}
    for key, options of data
      @attributes[key] = @_createAttribute(key, options)

  _createAttribute: (key, options) ->
    Object.defineProperty @modelClass.prototype, key,
      enumerable: yes
      get: -> @get(key)
      set: (value) -> @set(key, value)
    return options

module.exports = RModelSchema
