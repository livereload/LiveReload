
{ PluginManager } = require './plugin'

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


class exports.CommandProcessor

  constructor: (@send) ->

  'init': (data, callback) ->
    throw new Error("init requires pluginFolders") unless data.pluginFolders
    @pluginManager = new PluginManager(data.pluginFolders)
    @pluginManager.rescan (err) =>
      callback(err, command: "init.ok")
      @sendProjectList ->

  'tool.output.parse': (data, callback) ->
    parsed = @pluginManager.compilers[data.compiler].parser.parse(data.text)
    @send { command: 'tool.output.result', output: parsed.toJSON() }, callback

  sendProjectList: (callback) ->
    @send { command: 'mainwnd.set_project_list', projects: projectListJSON() }, callback
