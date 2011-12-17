{ PluginManager } = require '../lib/plugin'

pluginManager = null

exports.init = ({ pluginFolders }, callback) ->
  return callback(new Error("init requires pluginFolders")) unless pluginFolders

  LR.projects.init()

  LR.client.test_callback 10, (err, value) ->
    process.stderr.write "Err is #{err}\nValue = #{value}\n"

  pluginManager = new PluginManager(pluginFolders)
  pluginManager.rescan (err) ->
    return callback(err) if err

    LR.projects.updateProjectList (err) ->
      return callback(err) if err

      callback(null)
