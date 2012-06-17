debug = require('debug')('livereload:server')

wsio = require 'websocket.io'
http = require 'http'
Url  = require 'url'
fs   = require 'fs'

{ EventEmitter } = require 'events'

LRWebSocketConnection = require './connection'

DefaultWebSocketPort = parseInt(process.env['LRPortOverride'], 10) || 35729


class LRWebSocketServer extends EventEmitter

  constructor: (options={}) ->
    @port = options.port || DefaultWebSocketPort
    @connections = {}
    @activeConnections = 0
    @nextConnectionId = 1

  listen: (callback) ->
    @httpServer = http.createServer()
    try
      @httpServer.listen @port, (err) =>
        return callback(err) if err

        @httpServer.on 'request', (request, response) =>
          request.on 'end', =>
            url = Url.parse(request.url, yes)
            @emit 'httprequest', url, request, response

        @wsserver = wsio.attach(@httpServer)

        @wsserver.on 'connection', (socket) => @_createConnection(socket)

        callback(null)
    catch e
      callback(e)

  close: ->
    @httpServer.close()
    for own _, connection of @connections
      connection.close()
    return

  monitoringConnections: -> connection for own dummy, connection of @connections when connection.isMonitoring()

  monitoringConnectionCount: -> @monitoringConnections().length

  _createConnection: (socket) ->
    connection = new LRWebSocketConnection(socket, "C" + (@nextConnectionId++))

    connection.on 'connected', =>
      @connections[connection.id] = connection
      @emit 'connected', connection

    connection.on 'disconnected', =>
      delete @connections[connection.id]
      @emit 'disconnected', connection

    connection.on 'command', (command) =>
      @emit 'command', connection, command

    connection.on 'error', (err) =>
      @emit 'error', err, connection

    return connection


module.exports = LRWebSocketServer

