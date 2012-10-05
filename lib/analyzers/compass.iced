debug  = require('debug')('livereload:core:analyzer')
{ RelPathList } = require 'pathspec'

module.exports =
class CompassAnalyzer extends require('./base')

  message: "Detecting Compass"

  computePathList: ->
    RelPathList.parse(["*.rb", "*.config"])

  clear: ->
    @project.compassMarkers = []

  removed: (relpath) ->
    # TODO

  update: (relpath, fullPath, callback) ->
    # TODO
    callback()
