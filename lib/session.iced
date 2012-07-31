{ EventEmitter } = require 'events'
Project = require './projects/project'

class Session extends EventEmitter

  constructor: ->
    @projects = []
    @projectsMemento = {}

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

    face.on 'command', (message) =>
      @execute(message)

  # Hooks up and stores a newly added or loaded project.
  _addProject: (project) ->
    project.on 'change', (path) =>
      @emit 'command', command: 'reload', path: path
    @projects.push project
    return project


module.exports = Session

