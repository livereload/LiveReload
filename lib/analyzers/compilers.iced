debug  = require('debug')('livereload:core:analyzer')
{ RelPathList, RelPathSpec } = require 'pathspec'

module.exports =
class CompilersAnalyzer extends require('./base')

  message: "Determining compilers"

  computePathList: ->
    RelPathList.parse(["*.*"])

  clear: ->
    @project.compassMarkers = []

  removed: (relpath) ->
    # nop

  update: (file, callback) ->
    file.compiler = @findCompiler(file.relpath)

    if file.compiler
      file.outputNameMask or= "*." + file.compiler.destinationExt

    callback()

  findCompiler: (relpath) ->
    for compiler in @session.pluginManager.allCompilers
      # TODO: hande enabled state and the choice of Compass/Sass
      for spec in compiler.sourceSpecs
        if RelPathSpec.parseGitStyleSpec(spec).matches(relpath)
          debug "PathAnalyzer: #{relpath} matches compiler #{compiler.id}"
          return compiler

    null
