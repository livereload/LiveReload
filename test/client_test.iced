assert = require 'assert'

LRClient  = require '../lib/client'
LRServer  = require 'livereload-server'
WebSocket = require 'ws'

PORT = 32777


PROTOCOLS =
  monitoring: [LRClient.protocols.MONITORING_7]
  connCheck:  [LRClient.protocols.CONN_CHECK_1]


describe "LRClient", ->

  it "should connect to livereload-server", (done) ->
    server = new LRServer(port: PORT, id: "com.livereload.livereload-client.test.server", name: "TestServer", version: "1.0")
    await server.listen defer (err)
    throw err if err

    client = new LRClient(port: PORT, supportedProtocols: PROTOCOLS, WebSocket: WebSocket, id: "com.livereload.livereload-client.test.client", name: "TestClient", version: "1.0")

    await
      client.on 'connected', defer(negotiatedProtocols)
      server.once 'connected', defer(serverConnection)
      client.open()

    assert.equal negotiatedProtocols.monitoring, 7
    assert.equal negotiatedProtocols.connCheck,  1

    await
      client.once 'command', defer(reply)
      client.send { command: 'ping', token: 'test' }

    assert.equal reply.command, 'pong'
    assert.equal reply.token, 'test'

    client.close()
    server.close()
    done()
