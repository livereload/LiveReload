assert = require 'assert'
Path   = require 'path'

RPC = require "../#{process.env.JSLIB or 'lib'}/rpc/rpc"
MockTransport = require "../#{process.env.JSLIB or 'lib'}/rpc/transports/mock"


describe "RPC", ->

  beforeEach ->
    @events = []
    @rpc = new RPC(new MockTransport())
    @rpc.on 'command', (message, arg, cb) => @events.push ['command', message, arg]; cb(null)
    @rpc.on 'idle',                       => @events.push ['idle']


  it "should simply serialize a message that does not have a callback", ->
    @rpc.send 'foo', 42
    assert.deepEqual @rpc.transport.messages, [['foo', 42]]
    assert.deepEqual @events, []


  it "should send a simple message without a callback", ->
    @rpc.send 'foo', 42
    assert.deepEqual @rpc.transport.messages, [['foo', 42]]
    assert.deepEqual @events, []


  it "should handle a message round-trip involving a callback", ->
    cb = => @events.push ['callback-called']
    @rpc.send 'foo', 42, cb
    assert.deepEqual @rpc.transport.messages, [['foo', 42, '$1']]
    assert.deepEqual Object.keys(@rpc.callbacks), ['$1']
    assert.deepEqual @events, []

    @rpc.transport.simulate ['$1', 24]
    assert.deepEqual @events, [['callback-called']]


  it "should emit 'command' when a command message is received", (done) ->
    @rpc.transport.simulate ['foo', 42]
    process.nextTick => process.nextTick =>
      assert.deepEqual @rpc.transport.messages, []
      assert.deepEqual @events, [['command', 'foo', 42], ['idle']]
      done()
