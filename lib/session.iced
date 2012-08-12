debug = require('debug')('livereload:core:session')
{ EventEmitter } = require 'events'
Project = require './projects/project'

class Session extends EventEmitter

  constructor: ->
    @plugins = []
    @projects = []
    @projectsMemento = {}

    @addPlugin new (require('livereload-postproc'))()

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
    @_addProject new Project this, vfs, path

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

  # Hooks up and stores a newly added or loaded project.
  _addProject: (project) ->
    project.on 'change', (path) =>
      @emit 'command', command: 'reload', path: path
    @projects.push project
    return project

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

module.exports = Session

