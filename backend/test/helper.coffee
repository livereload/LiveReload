require 'sugar'
path = require 'path'

{ EventEmitter } = require 'events'

MemoryStream = require 'memorystream'

{ Communicator } = require '../lib/communicator'


exports.LRRoot        = LRRoot = path.join(__dirname, "../..")
exports.LRPluginsRoot = LRPluginsRoot = path.join(LRRoot, "LiveReload/Compilers")


class CommunicatorTwin extends EventEmitter
  constructor: ->
    @stdin  = new MemoryStream()
    @stdout = new MemoryStream(null, readable: no)
    @stdout.setEncoding('utf8')
    @stderr = new MemoryStream(null, readable: no)
    @stderr.setEncoding('utf8')
    @communicator = new Communicator(@stdin, @stdout, @stderr)
    @communicator.on 'end', =>
      @emit 'end'

  send: (command, data, callback) ->
    @stdin.write JSON.stringify([command, data]) + "\n"
    @communicator.once 'idle', callback

  end: ->
    @stdin.emit 'end'

  toString: -> @stdout.getAll()


exports.CommunicatorTwin = CommunicatorTwin
