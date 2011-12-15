{ PluginManager } = require '../lib/plugin'

pluginManager = null

exports.init = ({ pluginFolders }, callback) ->
  return callback(new Error("init requires pluginFolders")) unless pluginFolders

  pluginManager = new PluginManager(pluginFolders)
  pluginManager.rescan (err) ->
    return callback(err) if err

    LR.projects.updateProjectList (err) ->
      return callback(err) if err

      callback(null)
