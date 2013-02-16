assert       = require 'assert'
Path         = require 'path'
MemoryStream = require 'memorystream'

JSONStreamTransport = require "../#{process.env.JSLIB or 'lib'}/rpc/transports/jsonstream"


describe "RPC JSONStreamTransport", ->

  beforeEach ->
    @input  = new MemoryStream()
    @output = new MemoryStream(null, readable: no)
    @transport = new JSONStreamTransport(@input, @output)

    @messages = []
    @transport.on 'message', (message) =>
      @messages.push message


  it "should emit 'message' after receiving an incoming message", ->
    @input.write JSON.stringify(['foo', 42]) + "\n"
    assert.deepEqual @messages, [['foo', 42]]


  it "should emit 'message' twice after receiving two messages in one payload", ->
    @input.write JSON.stringify(['foo', 42]) + "\n" + JSON.stringify(['bar', 24]) + "\n"
    assert.deepEqual @messages, [['foo', 42], ['bar', 24]]
