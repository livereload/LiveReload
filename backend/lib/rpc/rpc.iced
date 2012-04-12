{ EventEmitter } = require 'events'


module.exports = class RPCSubsystem extends EventEmitter

  constructor: (@transport) ->
    @callbackTimeout = 2000
    @nextCallbackId = 1
    @callbacks = {}
    @timeouts  = {}
    @commandsInFlight = 0

    @transport.on 'message', (message) =>
      @executeWithProtection message

    @transport.on 'end', =>
      @emit 'end'


  send: (message, arg, callback=null) ->
    if typeof message isnt 'string'
      throw new Error("Invalid type of message: #{message}")
    if callback  #args.length > 0 && typeof args[args.length - 1] is 'function'
      callbackId = "$" + @nextCallbackId++
      @callbacks[callbackId] = callback
      # timeouts temporarily disabled because they prevent displayPopupMessage call from returning useful data
      # @timeouts[callbackId] = setInterval((-> handleCallbackTimeout(callbackId)), @callbackTimeout)
      @transport.send [message, arg, callbackId]
    else
      @transport.send [message, arg]


  executeWithProtection: (message) ->
    try
      await @execute(message, defer(err))
      if err
        @handleException err
    catch e
      @handleException e

  handleException: (err) ->
    unless @listeners('uncaughtException').length > 0
      throw err
    @emit 'uncaughtException', err


  execute: ([command, arg], callback) ->
    if command && typeof command is 'string'
      if command[0] is '$'
        @executeCallback(command, arg, callback)
      else
        @executeCommand(command, arg, callback)
    else
      callback(new Error("Invalid JSON received"))


  executeCallback: (command, arg, callback) ->
    if func = @callbacks[command]
      if @timeouts[command]
        clearTimeout(@timeouts[command])
      delete @timeouts[command]
      delete @callbacks[command]
      func null, arg
      callback(null)
    else
      callback(new Error("Unknown or duplicate callback received"))


  executeCommand: (command, arg, callback) ->
    ++@commandsInFlight

    await @emit('command', command, arg, defer(err))

    --@commandsInFlight

    # emit on next tick so that the callback has time to run first
    # (useful for testing, so that the callback can be the first to throw an assertion)
    if @commandsInFlight is 0
      process.nextTick =>
        if @commandsInFlight is 0
          @emit 'idle'

    callback(err)


  handleCallbackTimeout: (callbackId) ->
    func = @callbacks[callbackId]
    delete @timeouts[callbackId]
    delete @callbacks[callbackId]
    func new Error("timeout")
