assert = require 'assert'
Path   = require 'path'
wrap   = require '../wrap'

RPCSubsystem = require '../../lib/rpc/rpc'

{ MockRpcTransport } = require '../mocks'


describe "RPCSubsystem", ->

  beforeEach wrap ->
    @rpc = new RPCSubsystem(new MockRpcTransport())
    @rpc.iCanHazEvents()


  it "should simply serialize a message that does not have a callback", wrap ->
    @rpc.send 'foo', 42
    assert.deepEqual @rpc.transport.messages, [['foo', 42]]
    assert.deepEqual @rpc.events, []


  it "should send a simple message without a callback", wrap ->
    @rpc.send 'foo', 42
    assert.deepEqual @rpc.transport.messages, [['foo', 42]]
    assert.deepEqual @rpc.events, []


  it "should handle a message round-trip involving a callback", wrap ->
    cb = =>
      @rpc.events.push ['callback-called']
    @rpc.send 'foo', 42, cb
    assert.deepEqual @rpc.transport.messages, [['foo', 42, '$1']]
    assert.deepEqual Object.keys(@rpc.callbacks), ['$1']
    assert.equal @rpc.callbacks['$1'], cb
    assert.deepEqual @rpc.events, []

    @rpc.transport.simulate ['$1', 24]
    assert.deepEqual @rpc.events, [['callback-called']]


  it "should emit 'command' when a command message is received", wrap ->
    @rpc.transport.simulate ['foo', 42]
    assert.deepEqual @rpc.transport.messages, []
    for event in @rpc.events
      if typeof event.last() is 'function'
        event.pop()(null)
    assert.deepEqual @rpc.events, [['command', 'foo', 42], ['idle']]
