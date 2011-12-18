{ PluginManager } = require '../lib/plugin'

pluginManager = null

async = require 'async'

exports.init = ({ pluginFolders, preferencesFolder, version }, callback) ->
  return callback(new Error("init requires pluginFolders")) unless pluginFolders
  return callback(new Error("init requires preferencesFolder")) unless preferencesFolder

  LR.version = version || '0.0.0'

  pluginManager = new PluginManager(pluginFolders)

  async.series [
    (cb) -> LR.preferences.init preferencesFolder, cb
    (cb) -> pluginManager.rescan cb
    (cb) -> LR.websockets.init cb
    (cb) -> LR.projects.init cb
  ], (err) ->
    if err
      LR.client.app.failed_to_start(message: "#{err.message}")
      process.exit(1)
    LR.stats.startup()
    LR.log.fyi "Backend is up and running."
    callback()

exports.ping = (arg, callback) ->
  callback()
