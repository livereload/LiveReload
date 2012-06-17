debug = require('debug')('livereload:server')

{ EventEmitter } = require 'events'

Parser = require 'livereload-protocol'

HandshakeTimeout = 1000


class LRWebSocketConnection extends EventEmitter
  constructor: (@socket, @id) ->
    @parser = new Parser 'server',
      monitoring: [Parser.protocols.MONITORING_7]
      conncheck:  [Parser.protocols.CONN_CHECK_1]

    @socket.on 'message', (data) =>
      debug "LRWebSocketConnection(#{@id}) received #{data}"
      @parser.received(data)

    @socket.on 'close', =>
      (clearTimeout @_handshakeTimeout; @_handshakeTimeout = null) if @_handshakeTimeout
      @emit 'disconnected'

    @parser.on 'error', (err) =>
      @socket.close()
      @emit 'error', err

    @parser.on 'command', =>
      @emit 'command', command

    @parser.on 'connected', =>
      (clearTimeout @_handshakeTimeout; @_handshakeTimeout = null) if @_handshakeTimeout
      @send { command: "hello", protocols: @parser.supportedProtocolUrls, serverName: "LiveReload 2" }
      @emit 'connected'

    @_handshakeTimeout = setTimeout((=> @_handshakeTimeout = null; @socket.close()), HandshakeTimeout)

  close: ->
    @socket.close()

  send: (command) ->
    @parser.sending command
    @socket.send JSON.stringify(command)

  isMonitoring: ->
    @protocols.monitoring >= 7


module.exports = LRWebSocketConnection

