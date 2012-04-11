require 'sugar'
fs   = require 'fs'
Path = require 'path'

{ EventEmitter } = require 'events'

MemoryStream = require 'memorystream'

{ createApiTree }                = require 'apitree'
{ ApiTree, createRemoteApiTree } = require '../lib/util/remoteapitree'


exports.LRRoot        = LRRoot = Path.join(__dirname, "../..")
exports.LRPluginsRoot = LRPluginsRoot = Path.join(LRRoot, "LiveReload/Compilers")


class ProcessStdStreamsMock extends EventEmitter
  constructor: ->
    @stdin  = new MemoryStream()
    @stdout = new MemoryStream(null, readable: no)
    @stdout.setEncoding('utf8')
    @stderr = process.stderr
    # @stderr = new MemoryStream(null, readable: no)
    # @stderr.setEncoding('utf8')

  send: (command, data, callback) ->
    @stdin.write JSON.stringify([command, data]) + "\n"
    @communicator.once 'idle', callback

  end: ->
    @stdin.emit 'end'

  outputAsJson: ->
    JSON.parse(line) for line in @stdout.getAll().split("\n").compact(yes)


exports.setup = setup = (modules=[]) ->
  global.LR = LR =
    log:
      fyi: ->
      wtf: (message) -> LR.test.log.push ['wtf', message]
      omg: (message) -> LR.test.log.push ['omg', message]

    shutdownSilently: ->

    test:
      log: []

      # logCall: (name, args...) ->
      #   callback = (typeof args.last() is 'function') && args.pop()
      #   LR.test.log.push [name].concat(args)
      #   callback?(null)

      # allow: (apis...) ->
      #   callback = (typeof apis.last() is 'function') && apis.pop() || LR.test.logCall
      #   for api in apis
      #     LR.mount api, callback.fill(api)
      #   return

      # allowRPC: (apis...) ->
      #   callback = (typeof apis.last() is 'function') && apis.pop() || LR.test.logCall
      #   for api in apis
      #     LR.client.mount api, callback.fill("C.#{api}")
      #   return


beforeEach ->
  setup()

afterEach ->
  global.LR?.shutdownSilently()


exports.setupIntegrationTest = ->

  beforeEach (done) ->
    global.LR = LR = require('../config/env').createEnvironment()

    LR.test =
      exit: ->
      streams: new ProcessStdStreamsMock()

    LR.rpc.init(LR.test.streams, (-> LR.test.exit()), 60000)

    LR.app.init {
      pluginFolders:     [LRPluginsRoot]
      preferencesFolder: process.env['TMPDIR']
      version:           "1.2.3"
    }, done

  afterEach (done) ->
    LR.test.exit = done
    LR.test.streams.end()
