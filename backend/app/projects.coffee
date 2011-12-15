Path = require 'path'
fs   = require 'fs'

class Project
  constructor: (@path) ->
    @name = Path.basename(@path)

  toJSON: ->
    { @name, @path }

projects = []
projects.push new Project("Z:/example/naive_example")
projects.push new Project("Z:/example/file_example")

projectListJSON = ->
  (project.toJSON() for project in projects)

exports.updateProjectList = updateProjectList = (callback) ->
  LR.client.mainwnd.set_project_list { projects: projectListJSON() }
  callback(null)

exports.add = ({ path }, callback) ->
  fs.stat path, (err, stat) ->
    if err or not stat
      callback(err || new Error("File does not exist"))
    else
      projects.push new Project(path)
      updateProjectList (err) ->
        callback(err)
