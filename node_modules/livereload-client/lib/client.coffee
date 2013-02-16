{ EventEmitter } = require 'events'

LRParser = require 'livereload-protocol'


class LRClient extends EventEmitter

  @protocols = LRParser.protocols

  constructor: ({ @host, @port, id, name, version, supportedProtocols, WebSocket }) ->
    @host ?= 'localhost'
    @port ?= 35729

    ReWebSocket = require('rewebsocket')(WebSocket)

    @protocol = new LRParser 'client', supportedProtocols

    @connected = no

    @ws = new ReWebSocket("ws://#{@host}:#{@port}/livereload")
    @ws.onopen = =>
      @protocol.reset()
      @ws.send JSON.stringify(@protocol.hello({ id, name, version }))

    @ws.onclose = =>
      @connected = no
      @emit 'disconnected'

    @ws.onmessage = (event) =>
      @protocol.received event.data

    @protocol.on 'error', (err) =>
      console.error 'Error %s when parsing incoming message: %s', err.code, err.message
      @ws.reconnect()

    @protocol.on 'connected', (@negotiatedProtocols) =>
      @connected = yes
      @emit 'connected', @negotiatedProtocols

    @protocol.on 'command', (message) =>
      @emit 'command', message


  send: (message) ->
    if @connected
      @protocol.sending(message)
      @ws.send JSON.stringify(message)
      true
    else
      false

  open: ->
    @ws.open()

  close: ->
    @ws.close()


module.exports = LRClient
