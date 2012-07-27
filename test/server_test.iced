assert = require 'assert'
WebSocket = require 'ws'

LRWebSocketServer = require '../lib/server'
Parser = require 'livereload-protocol'

PORT = parseInt(process.env['LRPortOverride'], 10) || 35729


describe "LRWebSocketServer", ->

  it "should accept web socket connections", (done) ->
    server = new LRWebSocketServer(port: PORT, id: "com.livereload.livereload-server.test", name: "TestServer", version: "1.0")
    await server.listen defer (err)
    throw err if err

    ws = new WebSocket("ws://127.0.0.1:#{PORT}")

    await
      do(cb=defer()) ->
        await ws.on 'open', defer()
        ws.send JSON.stringify { command: 'hello', protocols: [Parser.protocols.MONITORING_7.url] }
        cb()
      ws.on 'message', defer (msg)

    msg = JSON.parse(msg)
    assert.equal msg.command, 'hello'

    server.close()
    done()

  # tests that existed in the previous version (not sure they make sense)
  it "should handle an error in httpServer.listen"
  it "should return all monitoring connections"
  it "should retransmit incoming commands as wscommand events"
  it "should handle socket disconnection"
