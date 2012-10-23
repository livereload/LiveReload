debug = require('debug')('livereload:core:session')
{ EventEmitter } = require 'events'
Project = require './projects/project'
{ PluginManager } = require './pluginmgr/plugin'

JobQueue = require 'jobqueue'

class Session extends EventEmitter

  constructor: (options={}) ->
    @plugins = []
    @projects = []
    @projectsMemento = {}

    @queue = new JobQueue()

    @CommandLineTool = require('./tools/cmdline')
    @MessageParser = require('./messages/parser')

    @addPlugin new (require('./plugins/compilation'))()
    @addPlugin new (require('./plugins/postproc'))()
    @addPlugin new (require('./plugins/refresh'))()

    @pluginManager = new PluginManager()

    @queue.register { action: 'rescan-plugins' }, @_rescanPlugins.bind(@)
    @queue.add { action: 'rescan-plugins' }

  addPluginFolder: (folder) ->
    @pluginManager.addFolder folder
    @queue.add { action: 'rescan-plugins' }

  setProjectsMemento: (vfs, @projectsMemento) ->
    @projects = []
    for own path, projectMemento of @projectsMemento
      project = @_addProject new Project(this, vfs, path)
      project.setMemento projectMemento
    return

  findProjectById: (projectId) ->
    for project in @projects
      if project.id is projectId
        return project
    null

  findProjectByPath: (path) ->
    for project in @projects
      if project.path is path
        return project
    null

  findProjectByUrl: (url) ->
    for project in @projects
      if project.matchesUrl url
        return project
    null

  findCompilerById: (compilerId) ->
    # return a fake compiler for now to test the memento loading code
    { id: compilerId }

  addProject: (vfs, path) ->
    project = new Project this, vfs, path
    @_addProject project
    project.setMemento {}

  startMonitoring: ->
    for project in @projects
      project.startMonitoring()

  close: ->
    for project in @projects
      project.stopMonitoring()

  addInterface: (face) ->
    @on 'command', (message) =>
      face.send(message)

    face.on 'command', (connection, message) =>
      @execute message, connection, (err) =>
        console.error err.stack if err

  addPlugin: (plugin) ->
    # sanity check
    unless typeof plugin.metadata is 'object'
      throw new Error "Missing plugin.metadata"
    unless plugin.metadata.apiVersion is 1
      throw new Error "Unsupported API version #{plugin.metadata.apiVersion} requested by plugin #{plugin.metadata.name}"
    @plugins.push plugin

    # for priority in plugin.jobPriorities || []
    #   @queue.addPriority priority

  handleChange: (vfs, root, paths) ->
    debug "Session.handleChange root=%j; paths: %j", root, paths
    runs = []
    for project in @projects
      if run = project.handleChange(vfs, root, paths)
        runs.push run
    return runs

  # Hooks up and stores a newly added or loaded project.
  _addProject: (project) ->
    project.on 'change', (path) =>
      @emit 'command', command: 'reload', path: path
    project.on 'action.start', (action) =>
      @emit 'action.start', project, action
    project.on 'action.finish', (action) =>
      @emit 'action.finish', project, action
    project.on 'run.start', (run) =>
      @emit 'run.start', project, run
    project.on 'run.finish', (run) =>
      @emit 'run.finish', project, run
    @projects.push project
    project.analyzer.addAnalyzerClass require('./analyzers/imports')
    project.analyzer.addAnalyzerClass require('./analyzers/compass')
    return project

  _removeProject: (project) ->
      if (index = @projects.indexOf(project)) >= 0
        @projects.splice index, 1
      undefined

  # message routing
  execute: (message, connection, callback) ->
    if func = @["on #{message.command}"]
      func.call(@, connection, message, callback)
    else
      debug "Ignoring unknown command #{message.command}: #{JSON.stringify(message)}"
      callback(null)

  'on save': (connection, message, callback) ->
    debug "Got save command for URL #{message.url}"
    project = @findProjectByUrl message.url
    if project
      debug "Save: project #{project.path} matches URL #{message.url}"
      project.saveResourceFromWebInspector message.url, message.content, callback
    else
      debug "Save: no match for URL #{message.url}"
      callback(null)

  sendBrowserCommand: (command) ->
    @emit 'browser-command', command

  _rescanPlugins: (request, done) ->
    @pluginManager.rescan(done)

module.exports = Session

