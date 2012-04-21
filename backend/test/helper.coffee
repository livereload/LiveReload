require 'sugar'
fs   = require 'fs'
Path = require 'path'

{ createRemoteApiTree } = require '../lib/util/remoteapitree'


exports.LRRoot        = LRRoot = Path.join(__dirname, "../..")
exports.LRPluginsRoot = LRPluginsRoot = Path.join(LRRoot, "LiveReload/Compilers")


class MockLRApplication
  constructor: ->
    @log =
      fyi: =>
      wtf: (message) => @test.log.push ['wtf', message]
      omg: (message) => @test.log.push ['omg', message]

    @test =
      log: []

      clearLog: =>
        @test.log = []

      logCall: (name, args...) =>
        callback = (typeof args.last() is 'function') && args.pop()
        @test.log.push [name].concat(args)
        callback?(null)

    messages = JSON.parse(fs.readFileSync(Path.join(__dirname, '../config/client-messages.json'), 'utf8'))
    messages.pop()
    @client = createRemoteApiTree(messages, (msg) => (args...) => throw new Error("Unexpected call to LR.client.#{msg}"))

    @client.allow = (apis...) =>
      callback = if typeof apis.last() is 'function' then apis.pop() else @test.logCall
      for api in apis
        @client.mount api, callback.fill("C.#{api}")
      return

    global.LR = this

  shutdownSilently: ->

exports.setup = setup = (modules=[]) ->
  new MockLRApplication()


beforeEach ->
  setup()

afterEach ->
  global.LR?.shutdownSilently()
