require 'sugar'

fs   = require 'fs'
path = require 'path'

{ EventEmitter }        = require 'events'
{ createApiTree }       = require 'apitree'
{ createRemoteApiTree } = require '../lib/remoteapitree'


exports.createEnvironment = (options, context) ->
  LR = createApiTree(context.paths.rpc)

  LR.events = new EventEmitter()

  messages = JSON.parse(fs.readFileSync(path.join(__dirname, 'client-messages.json'), 'utf8'))
  messages.pop()
  LR.client = createRemoteApiTree(messages, (msg) -> (args...) -> LR.rpc.send(msg, args...))

  LR
