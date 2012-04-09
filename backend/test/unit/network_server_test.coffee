assert = require 'assert'
wrap   = require '../wrap'

wsio = require 'websocket.io'
helper = require '../helper'

{ LRWebSocketServer } = require '../../lib/network/server'
{ MockHttpServer, MockWebSocketServer, MockWebSocket } = require '../mocks'

{ Parser, PROTOCOL_7, CONN_CHECK } = require '../../lib/network/protocol'


describe "LRWebSocketServer", ->
  beforeEach wrap ->
    @server = new LRWebSocketServer()
    @server.httpServer = new MockHttpServer()
    @server.wsserver   = new MockWebSocketServer()

    @shakeHands = (protocols, callback) =>
      @server.mockWebSockets = []
      @server.start (err) =>
        throw err if err

        ws = new MockWebSocket()
        @server.mockWebSockets.push ws

        @expect ws, 'send', (command) ->
          assert.equal JSON.parse(command).command, 'hello'

        if callback
          @server.on 'wsconnected', (connection) ->
            if connection.socket is ws
              callback(connection)

        @server.wsserver.emit 'connection', ws
        ws.emit 'message', JSON.stringify({ command: 'hello', protocols })


  it "should listen on port #{parseInt(process.env['LRPortOverride'], 10) || 35729}", wrap (done) ->
    @expect @server.httpServer, 'listen', (port, callback) =>
      assert.equal port, parseInt(process.env['LRPortOverride'], 10) || 35729
      callback(null)

    @server.start done


  it "should handle an error in httpServer.listen", wrap (done) ->
    error = new Error("something")

    @expect @server.httpServer, 'listen', (port, callback) => callback(error)

    @server.start (err) ->
      assert.equal err, error
      done()


  it "should process a v7 handshake", wrap (done) ->
    @server.on 'wsconnected', (connection) ->
      assert.equal connection.isMonitoring(), yes
      done()

    @shakeHands [PROTOCOL_7]


  it "should process a connection-check handshake", wrap (done) ->
    @server.on 'wsconnected', (connection) ->
      assert.equal connection.isMonitoring(), no
      done()

    @shakeHands [CONN_CHECK]


  it "should return all monitoring connections", wrap (done) ->
    @shakeHands [PROTOCOL_7], (connection) =>
      assert.deepEqual @server.monitoringConnections(), [connection]
      done()


  it "should retransmit incoming commands as wscommand events", wrap (done) ->
    @server.on 'wscommand', (connection, command) =>
      assert.equal command.command, 'info'
      done()

    @shakeHands [PROTOCOL_7], (connection) =>
      connection.socket.emit 'message', JSON.stringify({ command: 'info' })


  it "should handle socket disconnection", wrap (done) ->
    @server.on 'wsconnected', (connection) ->
      connection.socket.emit 'close'

    @server.on 'wsdisconnected', (connection) ->
      done()

    @shakeHands [PROTOCOL_7]
