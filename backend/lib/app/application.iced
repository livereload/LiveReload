fs   = require 'fs'
Path = require 'path'

{ EventEmitter }        = require 'events'

LRPluginManager = require '../plugins/manager'
RPC             = require '../rpc/rpc'

LRWebSocketController = require '../controllers/websockets'

# { createApiTree }       = require 'apitree'
{ createRemoteApiTree } = require '../util/remoteapitree'


get = (object, path) ->
  for component in path.split('.')
    object = object[component]
    throw new Error("Invalid RPC API method: '#{path}' (cannot find '#{component}')") if !object

  throw new Error("Invalid RPC API method: '#{path}' (not a callable function)") unless object.call?
  object


class LRApplication extends EventEmitter

  constructor: (rpcTransport) ->
    @_up = no

    @expirationDate = 'June 1, 2012'

    # instantiate services (cross-cutting concepts available to the entire application)
    @log         = new (require '../services/log')()
    @help        = new (require '../services/help')()
    @preferences = new (require '../services/preferences')()
    @console     = new (require '../services/console')()
    @stats       = new (require '../services/stats')()
    @appnewskit  = new (require '../services/appnewskit')()

    @fsmanager = new (require '../vfs/fsmanager')()
    @model = new (require '../model/model')(this)
    @ui = new (require '../ui/appui')()

    @rpc = new RPC(rpcTransport)

    @rpc.on 'end', =>
      @shutdown()

    @rpc.on 'command', (command, arg, callback) =>
      @invoke command, arg, callback

    @rpc.on 'uncaughtException', (err) =>
      details = "" + (err.stack || err.message || err)
      summary = details.split("\n").slice(0, 4).join("\n").trim()
      subject = details.split("\n")[0].trim()

      await C.app.displayPopupMessage {
        title:   "LiveReload 2 error"
        text:    "Whoops: LiveReload has just survived an error. If something stops working, you might want to restart the app. Sending the log file to the developer would be tremendously helpful too.\n\nGeeky details: #{summary}"
        buttons: [['report', 'Contact Support'], ['ignore', 'Ignore'], ['quit', 'Quit']]
      }, defer(err, result)
      if result is 'report'
        await
          LR.help.openSupportTicket "Error: #{subject}", '', defer()
          if @logFile
            C.app.revealFile { file: @logFile }, defer()
      else if result is 'quit'
        C.app.terminate()
      return

    messages = JSON.parse(fs.readFileSync(Path.join(__dirname, '../../config/client-messages.json'), 'utf8'))
    messages.pop()
    @client = createRemoteApiTree(messages, (msg) => (args...) => @rpc.send(msg, args...))

    @websockets = new LRWebSocketController()

    @_api =
      app:
        init: (arg, callback) => @start(arg, callback)
        ping: (arg, callback) => callback(null)   # simple do-nothing RPC roundtrip, used to unstuck IO streams on Windows
      projects:
        add: (arg, callback) =>
          callback(new Error("Not implemented yet"))
        remove: (arg, callback) =>
          callback(new Error("Not implemented yet"))
        changeDetected: (arg, callback) =>
          @fsmanager.handleFSChangeEvent arg, callback

    global.LR = this
    global.C = @client


  start: ({ resourcesDir, appDataDir, @logDir, @logFile, @version, @build, @platform }, callback) ->
    pluginFolders = [ Path.join(resourcesDir, 'plugins') ]
    preferencesFolder = Path.join(appDataDir, 'Data')

    console.log "pluginFolders = ", pluginFolders

    @isPurchased = await C.licensing.verifyReceipt {}, defer(_)
    @isFaithfulCitizen = (@build is 'appstore')

    # beta versions have soft expiration dates
    unless @isFaithfulCitizen
      if new Date().isAfter(@expirationDate)
        await C.app.displayPopupMessage {
          title:   "LiveReload 2 beta has expired"
          text:    "Hey! Thanks for trying our betas. This particular beta version of LiveReload has expired #{Date.create(@expirationDate).relative()}. It now begs you to ease its suffering and update to the latest one from http://livereload.com/."
          buttons: [['update', 'Visit Our Site'], ['launch', 'Brutally Ignore']]
        }, defer(err, result)
        if result is 'update'
          await C.app.openUrl "http://livereload.com/", defer()
          C.app.terminate()
          return callback(null)

    @_up = yes
    @pluginManager = new LRPluginManager(pluginFolders)

    errs = {}
    await
      @pluginManager.rescan defer(errs.pluginManager)
      @websockets.init defer(errs.websockets)
      @model.init defer(errs.model)

      for listener, index in @listeners('init')
        listener defer(errs["init#{index}"])

    for own _, err of errs when err
      return callback(err)

    # TODO:
    # LR.stats.startup()

    LR.log.fyi "Backend is up and running; starting the UI."

    if @platform is 'mac'
      await @ui.start defer()

    LR.log.fyi "App startup has been finished."
    callback(null)

  shutdownSilently: ->
    return unless @_up
    @_up = no

    @websockets.shutdown()

    # if global.LR is this
    #   delete global.LR

  shutdown: ->
    @shutdownSilently()
    @emit 'quit'

  invoke: (command, arg, callback) ->
    try
      get(@_api, command)(arg, callback)
    catch err
      callback(err)


module.exports = LRApplication
