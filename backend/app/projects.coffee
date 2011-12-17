Path = require 'path'
fs   = require 'fs'

nextProjectId = 1

class Project
  constructor: (@path) ->
    @id   = "P#{nextProjectId++}"
    @name = Path.basename(@path)
    LR.client.monitoring.add({ @id, @path })

  dispose: ->
    LR.client.monitoring.remove({ @id })

  toJSON: ->
    { @id, @name, @path }

projects = []

projectListJSON = ->
  (project.toJSON() for project in projects)

findById = (projectId) ->
  for project in projects
    if project.id is projectId
      return project
  null

exports.init = ->
  #

exports.updateProjectList = updateProjectList = (callback) ->
  LR.client.mainwnd.set_project_list { projects: projectListJSON() }
  callback(null)

exports.add = ({ path }, callback) ->
  fs.stat path, (err, stat) ->
    if err or not stat
      callback(err || new Error("The path does not exist"))
    else
      projects.push new Project(path)
      updateProjectList (err) ->
        callback(err)

exports.remove = ({ projectId }, callback) ->
  if project = findById(projectId)
    projects.splice projects.indexOf(project), 1
    updateProjectList (err) ->
      callback(err)
  else
    callback(new Error("The given project id does not exist"))

exports.changeDetected = ({ id, changes }, callback) ->
  if project = findById(id)
    process.stderr.write "Node: change detected in #{project.path}: #{JSON.stringify(changes)}\n"
  else
    process.stderr.write "Node: change detected in unknown id #{id}\n"
  callback(null)
