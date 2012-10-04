debug  = require('debug')('livereload:core:analyzer')
fs     = require 'fs'
Path   = require 'path'
Graph  = require './graph'
FSTree = require './tree'
{ RelPathList, RelPathSpec } = require 'pathspec'

module.exports =
class Analyzer

  constructor: (@project) ->
    @session = @project.session
    @queue   = @session.queue
    @queue.register { project: @project.id, action: 'analyzer-rebuild' }, { idKeys: ['project', 'action'] }, @_rebuild.bind(@)
    @queue.register { project: @project.id, action: 'analyzer-update' }, { idKeys: ['project', 'action'] }, @_update.bind(@)

    @_clear()


  rebuild: ->
    @queue.add { project: @project.id, action: 'analyzer-rebuild' }

  _rebuild: (request, done) ->
    tree = new FSTree(@project.fullPath)
    await tree.scan defer()

    list = new RelPathList()
    list.include RelPathSpec.parseGitStyleSpec('*.rb')
    list.include RelPathSpec.parseGitStyleSpec('*.config')

    for compiler in @session.pluginManager.allCompilers
      for spec in compiler.sourceSpecs
        list.include RelPathSpec.parseGitStyleSpec(spec)

    @_clear()
    relpaths = tree.getAllPaths()
    debug "Analyzer found #{relpaths.length} paths: " + relpaths.join(", ")
    relpaths = tree.findMatchingPaths(list)
    debug "Analyzer full rebuild will process #{relpaths.length} paths: " + relpaths.join(", ")
    for relpath in relpaths
      await @_updateFile relpath, defer()

    @_fullRebuildRequired = no
    done()

  update: (relpaths) ->
    return @rebuild() if @_fullRebuildRequired
    @queue.add { project: @project.id, action: 'analyzer-update', relpaths: relpaths.slice(0) }

  _update: (request, done) ->
    debug "Analyzer update job running."
    for relpath in request.relpaths
      await @_updateFile relpath, defer()
    done()

  _updateFile: (relpath, callback) ->
    debug "Analyzing #{relpath}"
    fullPath = Path.join(@project.fullPath, relpath)

    await fs.exists fullPath, defer(exists)
    unless exists
      debug "  ...was deleted"
      @imports.remove(relpath)
      return callback()

    # TODO: scan compass config file
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

    @imports.updateOutgoing relpath, importedRelPaths

    callback()

  _clear: ->
    @imports = new Graph()
    @compassMarkers = []
    @_fullRebuildRequired = yes
