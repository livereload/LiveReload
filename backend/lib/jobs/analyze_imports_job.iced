Job = require '../app/jobs'

module.exports = class AnalyzeImportsJob extends Job

  constructor: (@project, path) ->
    super [@project.id, path]

  merge: (sibling) ->

  execute: (callback) ->
    callback(null)
