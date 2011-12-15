Path = require 'path'

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

exports.updateProjectList = (callback) ->
  LR.client.mainwnd.set_project_list { projects: projectListJSON() }
  callback(null)
