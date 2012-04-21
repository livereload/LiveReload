
module.exports = class ProcessChangesJob

  constructor: (@project, @changedPaths) ->

  execute: (callback) ->
    LR.log.fyi "change detected in #{@path}: #{JSON.stringify(@changedPaths)}\n"
    for path in @changedPaths
      LR.websockets.sendReloadCommand { path }
    callback(null)
