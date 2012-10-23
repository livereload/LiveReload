debug  = require('debug')('livereload:core:analyzer')
fs     = require 'fs'
Path   = require 'path'
FSTree = require './tree'

module.exports =
class Analyzer

  constructor: (@project) ->
    @session = @project.session
    @queue   = @session.queue
    @queue.register { project: @project.id, action: 'analyzer-rebuild' }, { idKeys: ['project', 'action'] }, @_rebuild.bind(@)
    @queue.register { project: @project.id, action: 'analyzer-update' }, { idKeys: ['project', 'action'] }, @_update.bind(@)

    @analyzers = []

    @_fullRebuildRequired = yes

  addAnalyzerClass: (analyzerClass) ->
    analyzer = new analyzerClass(@project)
    @analyzers.push analyzer
    @rebuild()  # TODO: rebuild only this analyzer's data


  rebuild: ->
    @queue.add { project: @project.id, action: 'analyzer-rebuild' }

  _rebuild: (request, done) ->
    tree = new FSTree(@project.fullPath)
    await tree.scan defer()

    relpaths = tree.getAllPaths()
    debug "Analyzer found #{relpaths.length} paths: " + relpaths.join(", ")

    for analyzer in @analyzers
      debug "Running analyzer #{analyzer}"

      analyzer.clear()

      relpaths = tree.findMatchingPaths(analyzer.list)
      debug "#{analyzer} full rebuild will process #{relpaths.length} paths: " + relpaths.join(", ")
      for relpath in relpaths
        await @_updateFile analyzer, relpath, defer()

    @_fullRebuildRequired = no
    done()

  update: (relpaths) ->
    return @rebuild() if @_fullRebuildRequired
    @queue.add { project: @project.id, action: 'analyzer-update', relpaths: relpaths.slice(0) }

  _update: (request, done) ->
    debug "Analyzer update job running."
    for relpath in request.relpaths
      for analyzer in @analyzers
        if analyzer.list.matches(relpath)
          await @_updateFile analyzer, relpath, defer()
        else
          debug "#{analyzer} not interested in #{relpath}"
    done()

  _updateFile: (analyzer, relpath, callback) ->
    fullPath = Path.join(@project.fullPath, relpath)

    await fs.exists fullPath, defer(exists)
    unless exists
      debug "#{analyzer}: deleting info on #{relpath}"
      analyzer.removed(relpath)
      return callback()

    debug "#{analyzer}: analyzing #{relpath}"
    action = { id: 'analyze', message: "Analyzing #{Path.basename(relpath)}"}
    @project.reportActionStart(action)
    await analyzer.update relpath, fullPath, defer()
    @project.reportActionFinish(action)

    callback()
