fs   = require 'fs'
path = require 'path'

{ EventEmitter }        = require 'events'

LRPluginManager = require '../plugins/manager'
RPC             = require '../rpc/rpc'

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
    @native = createRemoteApiTree(messages, (msg) => (args...) => @rpc.send(msg, args...))

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
          callback(new Error("Not implemented yet"))

    global.LR = this

  start: ({ pluginFolders, preferencesFolder, @version }, callback) ->
    @pluginManager = new LRPluginManager(pluginFolders)

    await @pluginManager.rescan defer(err)
    return callback(err) if err

    @rpc.send 'foo', 42
    callback(null)

  shutdown: ->
    if global.LR is this
      delete global.LR

    @emit 'quit'

  invoke: (command, arg, callback) ->
    try
      get(@_api, command)(arg, callback)
    catch err
      callback(err)


module.exports = LRApplication
