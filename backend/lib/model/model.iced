
fs = require 'fs'

LRWorkspace = require './workspace'


module.exports = class LRModel

  constructor: (@application) ->


  loadModel: (callback) ->
    await @application.preferences.loadLegacyModel defer(err, memento)
    return callback(err) if err

    @workspace = new LRWorkspace(memento)
    console.log "Loaded #{@workspace.projects.length} project(s)."

    @workspace.init callback

    # LR.preferences.get PREF_KEY, (memento) =>
    #   for projectMemento in memento.projects || []
    #     @projects.push new Project(projectMemento)
    #   callback()

  saveModel: ->
    memento = {
      projects: (p.toMemento() for p in @projects)
    }
    LR.preferences.set PREF_KEY, memento

  modelDidChange: (callback) ->
    @saveModel()
    @updateProjectList callback

  updateProjectList: (callback) ->
    LR.client.mainwnd.setProjectList { projects: @projectListJSON() }
    callback(null)

  projectListJSON: ->
    (project.toJSON() for project in @projects)

  findById: (projectId) ->
    for project in @projects
      if project.id is projectId
        return project
    null

  init: (callback) ->
    await @loadModel defer(err)
    # await @updateProjectList defer()
    callback(err)

  add: ({ path }, callback) ->
    fs.stat path, (err, stat) =>
      if err or not stat
        callback(err || new Error("The path does not exist"))
      else
        @projects.push new Project({ path })
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
