{ PluginManager } = require '../lib/plugin'

pluginManager = null

async = require 'async'

runTestCallback = (cb) ->
  LR.client.test_callback 10, (err, value) ->
    process.stderr.write "Err is #{err}\nValue = #{value}\n"
    cb(err)

exports.init = ({ pluginFolders, preferencesFolder }, callback) ->
  return callback(new Error("init requires pluginFolders")) unless pluginFolders
  return callback(new Error("init requires preferencesFolder")) unless preferencesFolder

  pluginManager = new PluginManager(pluginFolders)

  async.series [
    (cb) -> LR.preferences.init preferencesFolder, cb
    (cb) -> pluginManager.rescan cb
    (cb) -> LR.websockets.init cb
    (cb) -> runTestCallback cb
    (cb) -> LR.projects.init cb
  ], (err) ->
    if err
      LR.client.app.failed_to_start(message: "#{err.message}")
      process.exit(1)
    callback()
