Path  = require 'path'
async = require 'async'

exports.api =
  init: ({ resourcesDir, appDataDir, logDir, logFile, version, build, platform }, callback) ->
    return callback(new Error("init requires resourcesDir")) unless resourcesDir
    return callback(new Error("init requires appDataDir"))   unless appDataDir
    return callback(new Error("init requires logDir"))       unless logDir

    pluginFolders = [resourcesDir]
    preferencesFolder = Path.join(appDataDir, 'Data')

    LR.version = version || '0.0.0'

    async.series [
      # (cb) -> LR.preferences.init preferencesFolder, cb
      (cb) -> LR.plugins.init pluginFolders, cb
      (cb) -> LR.websockets.init cb
      # (cb) -> LR.projects.init cb
    ], (err) ->
      if err
        LR.client.app.failedToStart(message: "#{err.message}")
        LR.rpc.exit(1)
        return callback(null)  # in case we're in tests and did not exit
      LR.stats.startup()
      LR.log.fyi "Backend is up and running."
      callback()

  ping: (arg, callback) ->
    callback()


exports.displayCriticalError = ({title, text, url, button}) ->
  button ?= "More Info"

  LR.log.omg "#{title} -- #{text}"
  LR.client.app.displayPopupMessage {
      title, text, buttons: [['help', button], ['quit', "Quit"]]
    }, (err, result) ->
      if result == 'help'
        LR.client.app.openUrl url
      LR.client.app.terminate()


exports.displayHelpfulWarning = ({title, text, url, button}) ->
  button ?= "More Info"

  LR.log.wtf "#{title} -- #{text}"
  LR.client.app.displayPopupMessage {
      title, text, buttons: [['help', button], ['ignore', "Ignore"]]
    }, (err, result) ->
      if result == 'help'
        LR.client.app.openUrl url
