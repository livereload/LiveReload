debug  = require('debug')('livereload:core:analyzer')
fs     = require 'fs'
Path   = require 'path'
Graph  = require '../projects/graph'

{ RelPathList, RelPathSpec } = require 'pathspec'

module.exports =
class ImportAnalyzer extends require('./base')

  message: "Computing imports"

  computePathList: ->
    list = new RelPathList()
    for compiler in @session.pluginManager.allCompilers
      for spec in compiler.sourceSpecs
        list.include RelPathSpec.parseGitStyleSpec(spec)
    return list

  clear: ->
    @project.imports = new Graph()

  removed: (relpath) ->
    @project.imports.remove(relpath)

  update: (relpath, fullPath, callback) ->
    for compiler in @session.pluginManager.allCompilers
      for spec in compiler.sourceSpecs
        if RelPathSpec.parseGitStyleSpec(spec).matches(relpath)
          debug "  ...#{relpath} matches compiler #{compiler.name}"
          await @_updateCompilableFile relpath, fullPath, compiler, defer()
    callback()

  _updateCompilableFile: (relpath, fullPath, compiler, callback) ->
    await fs.readFile fullPath, 'utf8', defer(err, text)
    if err
      debug "Error reading #{fullPath}: #{err}"
      return callback()

    fragments = []
    for re in compiler.importRegExps
      text.replace re, ($0, fragment) ->
        debug "  ... ...found import of '#{fragment}'"
        fragments.push fragment
        $0

    importedRelPaths = []
    for fragment in fragments
      await @project.vfs.findFilesMatchingSuffixInSubtree @project.path, fragment, Path.basename(relpath), defer(err, result)
      if err
        debug "  ... ...error in findFilesMatchingSuffixInSubtree: #{err}"
      else if result.bestMatch
        debug "  ... ...imported file found at #{result.bestMatch.path}"
        importedRelPaths.push result.bestMatch.path
      else
        debug "  ... ...imported file not found in project tree"

    debug "  ...imported paths = " + JSON.stringify(importedRelPaths)

    @project.imports.updateOutgoing relpath, importedRelPaths

    callback()
