
class RModel

  constructor: ->
    @attributes = {}
    @initialize()

  initialize: ->

  get: (attr) ->
    @attributes[attr]

  has: (attr) ->
    @attributes[attr]?

  set: (attr, value) ->
    @attributes[attr] = value


module.exports = RModel
