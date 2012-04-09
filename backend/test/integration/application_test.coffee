assert       = require 'assert'
MemoryStream = require 'memorystream'
wrap         = require '../wrap'

LRApplication = require '../../lib/app/application'
LineOrientedStreamTransport = require '../../lib/rpc/streamtransport'

{ MockRpcTransport } = require '../mocks'


describe "LiveReload", ->

  it "should start up with a mock transport", (done) ->
    application = new LRApplication(new MockRpcTransport())
    application.start { pluginFolders: ["/abc", "/def"], preferencesFolder: "/ghi", version: "1.2.3" }, (err) ->
      assert.equal err, null
      done()

  it "should start up successfully", wrap (done) ->
    @input  = new MemoryStream()
    @output = new MemoryStream(null, readable: no)
    application = new LRApplication(new LineOrientedStreamTransport(@input, @output))
    application.start { pluginFolders: ["/abc", "/def"], preferencesFolder: "/ghi", version: "1.2.3" }, (err) ->
      assert.equal err, null
      done()

  it "should start up via the top-level module", (done) ->
    input  = new MemoryStream()
    output = new MemoryStream(null, readable: no)
    exit = ->
      assert no
    require('../../lib/livereload').run(input, output, ['--console'], exit)
    process.nextTick => process.nextTick => process.nextTick => done()
