fs   = require 'fs'
path = require 'path'

{ EventEmitter }        = require 'events'

LRPluginManager = require '../plugins/manager'
RPC             = require '../rpc/rpc'

# { createApiTree }       = require 'apitree'
{ createRemoteApiTree } = require '../util/remoteapitree'


class LRRemoteApi

  constructor: (@application) ->

  invoke: (command, arg, callback) ->
    LR.log.wtf "Ignoring command #{command}"
    callback(null)

  # get = (object, path) ->
  #   for component in path.split('.')
  #     object = object[component]
  #     throw new Error("Cannot find #{path}") if !object

  #   throw new Error("#{path} is not callable") unless object.call?
  #   object


  # exports.execute = execute = (message, args..., callback) ->
  #   message = message.replace /\.(\w+)$/, '.api.$1'
  #   try
  #     get(LR, message)(args..., callback)
  #   catch e
  #     callback(e)



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

    @_api = new LRRemoteApi(this)

    global.LR = this

  start: ({ pluginFolders, preferencesFolder, @version }, callback) ->
    @pluginManager = new LRPluginManager(pluginFolders)
    @rpc.send 'foo', 42
    callback(null)

  shutdown: ->
    if global.LR is this
      delete global.LR

    @emit 'quit'

  invoke: (command, arg, callback) ->
    @_api.invoke command, arg, callback


module.exports = LRApplication
