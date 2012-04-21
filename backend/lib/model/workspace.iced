
fs = require 'fs'

{ Project } = require './project'

class LRWorkspace

  constructor: (@memento={}) ->
    @globalMonitoringRequests = {}

    @projects = []
    for own path, projectMemento of @memento
      @projects.push new Project(this, path, memento)

  _initializeProject: (project) ->
    for own key, state of @globalMonitoringRequests
      project.requestMonitoring key, state
    return project

  init: (callback) ->
    for project in @projects
      @_initializeProject project
    callback(null)

  findById: (projectId) ->
    for project in @projects
      if project.id is projectId
        return project
    null

  add: ({ path }, callback) ->
    fs.stat path, (err, stat) =>
      if err or not stat
        callback(err || new Error("The path does not exist"))
      else
        @projects.push @_initializeProject(new Project({ path }))
        @modelDidChange callback

  remove: ({ projectId }, callback) ->
    if project = @findById(projectId)
      @projects.splice @projects.indexOf(project), 1
      @modelDidChange callback
    else
      callback(new Error("The given project id does not exist"))

  changeDetected: ({ id, changes }, callback) ->
    if project = @findById(id)
      project.handleChange changes, callback
    else
      callback(new Error("Change detected in unknown project id #{id}"))

  requestMonitoring: (key, state) ->
    @globalMonitoringRequests[key] = state
    for project in @projects
      project.hive.requestMonitoring key, state
    undefined

module.exports = LRWorkspace
