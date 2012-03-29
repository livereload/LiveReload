wsio = require 'websocket.io'
http = require 'http'
Url  = require 'url'
Path = require 'path'
fs   = require 'fs'

{ EventEmitter } = require 'events'

{ Parser, PROTOCOL_7, CONN_CHECK } = require './protocol'

HandshakeTimeout = 1000
DefaultPort = 35729


_connections = {}
_nextConnectionId = 1


class LRWebSocketConnection
  constructor: (@server, @socket, @id) ->
    @socket.on 'message', @_ondata.bind(@)
    @socket.on 'close',   @_onclose.bind(@)

    @parser = new Parser
    @parser.on 'connected', @_onHandshakeDone.bind(@)
    @parser.on 'oldproto',  @_onoldproto.bind(@)
    @parser.on 'message',   @_oncommand.bind(@)
    @parser.on 'error',     @_onerror.bind(@)

    @handshakeTimeout = setTimeout(@_onHandshakeTimeout.bind(@), HandshakeTimeout)

  send: (command) ->
    payload = JSON.stringify(command)
    LR.log.fyi "#{@id}: Sending message #{payload}"
    @socket.send payload

  isMonitoring: -> !!@protocols.monitoring

  _ondata: (payload) ->
    LR.log.fyi "#{@id}: Got message #{payload}"
    @parser.process(payload)

  _onclose: (e) ->
    @_cancelHandshakeTimeout()
    @server._onwsdisconnected(@)
    LR.log.fyi "#{@id}: Connection closed."

  _onerror: (err) ->
    LR.log.wtf "#{@id}: Web Socket communication error: #{err.message}"
    @socket.close()

  _onoldproto: ->
    LR.log.wtf "#{@id}: Web Socket: old protocol v6 connection detected"
    @socket.close()
    @server._onwsoldproto(@)

  _onHandshakeTimeout: ->
    @handshakeTimeout = null
    LR.log.wtf "#{@id}: Web Socket handshake timeout"
    @socket.close()

  _cancelHandshakeTimeout: ->
    if @handshakeTimeout
      clearTimeout @handshakeTimeout
      @handshakeTimeout = null

  _onHandshakeDone: (protocols) ->
    @protocols = protocols
    @_cancelHandshakeTimeout()
    @send {
      command:    "hello"
      protocols:  [PROTOCOL_7, CONN_CHECK]
      serverName: "LiveReload 2"
    }
    @server._onwsconnected(@)
    LR.log.fyi "#{@id}: Web Socket handshake done, connected."

  _oncommand: (command) ->
    LR.log.fyi "#{@id}: Incoming command #{command.command}"
    @server._onwscommand(@, command)


class LRWebSocketServer extends EventEmitter

  constructor: (options={}) ->
    @port = options.port || DefaultPort
    @connections = {}
    @activeConnections = 0
    @nextConnectionId = 1

  start: (callback) ->
    @httpServer ||= http.createServer()  # non-nil when running tests
    try
      @httpServer.listen @port, (err) =>
        return callback(err) if err

        @httpServer.on 'request', (request, response) =>
          request.on 'end', =>
            url = Url.parse(request.url, yes)
            @emit 'httprequest', url, request, response

        @wsserver ||= wsio.attach(@httpServer)

        @wsserver.on 'connection', (socket) =>
          new LRWebSocketConnection(@, socket, "C" + (@nextConnectionId++))

        callback(null)
    catch e
      callback(e)

  monitoringConnections: -> connection for own dummy, connection of @connections when connection.isMonitoring()

  monitoringConnectionCount: -> @monitoringConnections().length

  _onwsconnected: (connection) ->
    @connections[connection.id] = connection
    @emit 'wsconnected', connection

  _onwsdisconnected: (connection) ->
    delete @connections[connection.id]
    @emit 'wsdisconnected', connection

  _onwscommand: (connection, command) ->
    @emit 'wscommand', connection, command

  _onwsoldproto: (connection) ->
    @emit 'wsoldproto', connection


module.exports = { LRWebSocketServer }
