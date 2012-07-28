# Path  = require 'path'
# fs    = require 'fs'
# async = require 'async'

# nextProjectId = 1

# PREF_KEY = 'projects'

# class Project
#   constructor: (memento={}) ->
#     @path = memento.path
#     @id   = "P#{nextProjectId++}"
#     @name = Path.basename(@path)
#     LR.client.monitoring.add({ @id, @path })

#   dispose: ->
#     LR.client.monitoring.remove({ @id })

#   toJSON: ->
#     { @id, @name, @path }

#   toMemento: ->
#     { @path }

#   handleChange: (paths, callback) ->
#     LR.log.fyi "change detected in #{@path}: #{JSON.stringify(paths)}\n"
#     for path in paths
#       LR.websockets.sendReloadCommand { path }
#     callback(null)


# projects = []

# loadModel = (callback) ->
#   LR.preferences.get PREF_KEY, (memento) ->
#     for projectMemento in memento.projects || []
#       projects.push new Project(projectMemento)
#     callback()

# saveModel = ->
#   memento = {
#     projects: (p.toMemento() for p in projects)
#   }
#   LR.preferences.set PREF_KEY, memento

# modelDidChange = (callback) ->
#   saveModel()
#   updateProjectList callback

# projectListJSON = ->
#   (project.toJSON() for project in projects)

# exports.findById = findById = (projectId) ->
#   for project in projects
#     if project.id is projectId
#       return project
#   null

# exports.init = (callback) ->
#   async.series [loadModel, updateProjectList], callback

# exports.updateProjectList = updateProjectList = (callback) ->
#   LR.client.mainwnd.setProjectList { projects: projectListJSON() }
#   callback(null)

exports.api =
  add: ({ path }, callback) ->
    # fs.stat path, (err, stat) ->
    #   if err or not stat
    #     callback(err || new Error("The path does not exist"))
    #   else
    #     projects.push new Project({ path })
    #     modelDidChange callback

  remove: ({ projectId }, callback) ->
    # if project = findById(projectId)
    #   projects.splice projects.indexOf(project), 1
    #   modelDidChange callback
    # else
    #   callback(new Error("The given project id does not exist"))

  changeDetected: ({ id, changes }, callback) ->
    # if project = findById(id)
    #   project.handleChange changes, callback
    # else
    #   callback(new Error("Change detected in unknown project id #{id}"))
