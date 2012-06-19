{ EventEmitter } = require 'events'
Project = require './project'

class Session extends EventEmitter

  constructor: ->
    @projects = []

  addProject: (vfs, path) ->
    project = new Project vfs, path
    @projects.push project
    project.on 'change', (path) =>
      @emit 'command', command: 'reload', path: path
    project

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


module.exports = Session

