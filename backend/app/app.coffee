async = require 'async'

exports.init = ({ pluginFolders, preferencesFolder, version }, callback) ->
  return callback(new Error("init requires pluginFolders")) unless pluginFolders
  return callback(new Error("init requires preferencesFolder")) unless preferencesFolder

  LR.version = version || '0.0.0'

  async.series [
    (cb) -> LR.preferences.init preferencesFolder, cb
    (cb) -> LR.plugins.init pluginFolders, cb
    (cb) -> LR.websockets.init cb
    (cb) -> LR.projects.init cb
  ], (err) ->
    if err
      LR.client.app.failedToStart(message: "#{err.message}")
      LR.rpc.exit(1)
      return callback(null)  # in case we're in tests and did not exit
    LR.stats.startup()
    LR.log.fyi "Backend is up and running."
    callback()

exports.ping = (arg, callback) ->
  callback()
