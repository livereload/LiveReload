async = require 'async'

exports.api =
  init: ({ pluginFolders, preferencesFolder, version }, callback) ->
    return callback(new Error("init requires pluginFolders")) unless pluginFolders
    return callback(new Error("init requires preferencesFolder")) unless preferencesFolder

    LR.version = version || '0.0.0'

    async.series [
      (cb) -> LR.plugins.init pluginFolders, cb
      (cb) -> LR.websockets.init cb
    ], (err) ->
      if err
        LR.client.app.failedToStart(message: "#{err.stack or err.message or err}")
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
