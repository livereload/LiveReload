
{ Communicator } = require '../lib/communicator'

communicator = null

get = (object, path) ->
  for component in path.split('.')
    object = object[component]
    throw new Error("Cannot find #{path}") if !object

  throw new Error("#{path} is not callable") unless object.call?
  object


exports.init = (streams, exit) ->
  communicator = new Communicator streams.stdin, streams.stdout, streams.stderr, execute
  communicator.on 'end', -> exit(0)

exports.send = (message, args...) ->
  communicator.send message, args...

exports.execute = execute = (message, args..., callback) ->
  try
    get(LR, message)(args..., callback)
  catch e
    callback(e)
