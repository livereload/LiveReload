fs   = require 'fs'
path = require 'path'

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

    # instantiate services (cross-cutting concepts available to the entire application)
    @log  = new (require '../services/log')()
    @help = new (require '../services/help')()

    @rpc = new RPC(rpcTransport)

    @rpc.on 'end', =>
      @shutdown()

    @rpc.on 'command', (command, arg, callback) =>
      @invoke command, arg, callback

    messages = JSON.parse(fs.readFileSync(path.join(__dirname, '../../config/client-messages.json'), 'utf8'))
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
          callback(new Error("Not implemented yet"))
      websockets:
        sendReloadCommand: (arg, callback) =>
          @websockets.sendReloadCommand(arg)
          callback(null)

    global.LR = this


  start: ({ pluginFolders, preferencesFolder, @version }, callback) ->
    @_up = yes
    @pluginManager = new LRPluginManager(pluginFolders)

    errs = {}
    await
      @pluginManager.rescan defer(errs.pluginManager)
      @websockets.init defer(errs.websockets)

    for own _, err of errs when err
      return callback(err)

    # TODO:
    # if err
    #   LR.client.app.failedToStart(message: "#{err.message}")
    #   LR.rpc.exit(1)
    #   return callback(null)  # in case we're in tests and did not exit
    # LR.stats.startup()
    # LR.log.fyi "Backend is up and running."

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
