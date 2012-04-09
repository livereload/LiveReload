assert = require 'assert'
Path   = require 'path'
wrap   = require '../wrap'

LineOrientedStreamTransport = require '../../lib/rpc/streamtransport'
{ LRPluginsRoot } = require '../helper'
MemoryStream = require 'memorystream'


describe "LineOrientedStreamTransport", ->

  beforeEach wrap ->
    @input  = new MemoryStream()
    @output = new MemoryStream(null, readable: no)
    @transport = new LineOrientedStreamTransport(@input, @output)

    @messages = []
    @transport.on 'message', (message) =>
      @messages.push message


  it "should emit 'message' after receiving an incoming message", wrap ->
    @input.write JSON.stringify(['foo', 42]) + "\n"
    assert.deepEqual @messages, [['foo', 42]]


  it "should emit 'message' twice after receiving two messages in one payload", wrap ->
    @input.write JSON.stringify(['foo', 42]) + "\n" + JSON.stringify(['bar', 24]) + "\n"
    assert.deepEqual @messages, [['foo', 42], ['bar', 24]]
