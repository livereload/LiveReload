debug  = require('debug')('livereload:core:analyzer')
fs     = require 'fs'
Path   = require 'path'
_      = require 'underscore'

Graph  = require '../projects/graph'

{ RelPathList, RelPathSpec } = require 'pathspec'
{ CompilationRule } = require '../misc/rule'

module.exports =
class RuleAnalyzer extends require('./base')

  message: "Computing path rules"

  computePathList: ->
    list = new RelPathList()
    for compiler in @session.pluginManager.allCompilers
      for spec in compiler.sourceSpecs
        list.include RelPathSpec.parseGitStyleSpec(spec)
    return list

  clear: ->

  removed: (relpath) ->

  update: (file, callback) ->
    callback()

  after: (callback) ->
    compilablePaths = @project.tree.findMatchingPaths(@list)
    compilableFiles = _.compact(@project.fileAt(path) for path in compilablePaths)

    implicitRules = []
    for compiler in @project.availableCompilers
      if @project.tree.findMatchingPaths(compiler.sourceFilter).length > 0
        rule = new CompilationRule()
        rule.sourceSpec = "**/*." + compiler.extensions[0]
        rule.destSpec = "**/*." + compiler.destinationExt

    @project.rules = implicitRules

    callback()
