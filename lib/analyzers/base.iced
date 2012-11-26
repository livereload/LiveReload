
module.exports =
class Analyzer

  constructor: (@project) ->
    @session = @project.session

    @initialize?()
    @clear()

  toString: -> @constructor.name

  Object.defineProperty @::, 'list', get: ->
    @_list or= @computePathList()

  after: (callback) ->
    callback()


