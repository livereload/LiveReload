
module.exports =
class Action

  constructor: (@id, @name) ->

  toString: ->
    "#{@constructor.name}(#{@id})"

  createDefaultRules: ->
    []
