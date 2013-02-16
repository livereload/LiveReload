debug = require('debug')('livereload:cli:rpc')
Path  = require 'path'

if process.platform is 'win32'
  AppVFS = require('vfs-local').LocalVFS
else
  AppVFS = require '../lib/vfs-app'

LRWebSocketController = require '../lib/network/controller'

exports.api =
  init: ({ resourcesDir, appDataDir, logDir, logFile, rubies, version, build, platform }, callback) ->
    return callback(new Error("init requires resourcesDir")) unless resourcesDir
    return callback(new Error("init requires appDataDir"))   unless appDataDir
    return callback(new Error("init requires logDir"))       unless logDir

    debug "Initializing LiveReload backend with folders: " + JSON.stringify({ resourcesDir, appDataDir, logDir, logFile, version, build, platform })

    LR.version = version || '0.0.0'

    context = this
    context.setupRuntime({ version, appDataDir })

    context.websockets = new LRWebSocketController(this)
    await context.websockets.init defer(err)

    if err
      LR.client.app.failedToStart(message: "#{err.message}")
      LR.rpc.exit(1)
      return callback(null)  # in case we're in tests and did not exit

    context.stats.startup()

    for ruby in rubies or []
      @session.addRuby(ruby)

    @appVfs = new AppVFS(LR.client)

    LR.client.app.requestModel({})

    LR.projects.init(@appVfs, @session, appDataDir)

    debug "Backend is up and running."
    callback()

  ping: (arg, callback) ->
    callback()

  reloadLegacyProjects: (memento, callback) ->
    @session.setProjectsMemento @appVfs, memento
    callback()

  handleChange: ({root, paths}, callback) ->
    @session.handleChange @appVfs, root, paths
    callback(null)


exports.displayCriticalError = ({title, text, url, button}) ->
  button ?= "More Info"

  if process.platform is 'win32'
    LR.rpc.send 'app.displayCriticalError', {title, text, url, button}
    return

  debug "ERROR (displayCriticalError): #{title} -- #{text}"
  LR.client.app.displayPopupMessage {
      title, text, buttons: [['help', button], ['quit', "Quit"]]
    }, (err, result) ->
      if result == 'help'
        LR.client.app.openUrl url
      LR.client.app.terminate()


exports.displayHelpfulWarning = ({title, text, url, button}) ->
  button ?= "More Info"

  debug "Warning (displayHelpfulWarning): #{title} -- #{text}"
  LR.client.app.displayPopupMessage {
      title, text, buttons: [['help', button], ['ignore', "Ignore"]]
    }, (err, result) ->
      if result == 'help'
        LR.client.app.openUrl url
