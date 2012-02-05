
{ Communicator } = require '../lib/communicator'

communicator = null

callbacks = {}
timeouts  = {}
nextCallbackId = 1

_callbackTimeout = null
_exit = null

get = (object, path) ->
  for component in path.split('.')
    object = object[component]
    throw new Error("Cannot find #{path}") if !object

  throw new Error("#{path} is not callable") unless object.call?
  object


exports.init = (streams, exit, { callbackTimeout, consoleDebuggingMode }={}) ->
  _callbackTimeout = callbackTimeout ? 2000
  _exit = exit
  communicator = new Communicator streams.stdin, streams.stdout, streams.stderr, executeJSON, consoleDebuggingMode
  communicator.on 'end', -> exit(0)

exports.exit = (rv) ->
  _exit(rv)

exports.send = (message, arg, callback=null) ->
  if typeof message isnt 'string'
    throw new Error("Invalid type of message: #{message}")
  if callback  #args.length > 0 && typeof args[args.length - 1] is 'function'
    callbackId = "$" + nextCallbackId++
    callbacks[callbackId] = callback
    timeouts[callbackId] = setInterval((-> handleCallbackTimeout(callbackId)), _callbackTimeout)
    communicator.send [message, arg, callbackId]
  else
    communicator.send [message, arg]

exports.execute = execute = (message, args..., callback) ->
  try
    get(LR, message)(args..., callback)
  catch e
    callback(e)

executeJSON = (json, callback) ->
  [command, arg] = json
  if command && typeof command is 'string'
    if command[0] is '$'
      if func = callbacks[command]
        if timeouts[command]
          clearTimeout(timeouts[command])
        delete timeouts[command]
        delete callbacks[command]
        func null, arg
        callback(null)
      else
        callback(new Error("Unknown or duplicate callback received"))
    else
      execute(command, arg, callback)
  else
    callback(new Error("Invalid JSON received"))

handleCallbackTimeout = (callbackId) ->
  func = callbacks[callbackId]
  delete timeouts[callbackId]
  delete callbacks[callbackId]
  func new Error("timeout")
