
{ EventEmitter } = require 'events'

exports.PROTOCOL_7 = PROTOCOL_7 = 'http://livereload.com/protocols/official-7'
exports.CONN_CHECK = CONN_CHECK = 'http://livereload.com/protocols/connection-check-1'

exports.ProtocolError = class ProtocolError
  constructor: (reason, data) ->
    @message = "LiveReload protocol error (#{reason}) after receiving data: \"#{data}\"."

exports.Parser = class Parser extends EventEmitter
  constructor: ->
    @reset()

  reset: ->
    @protocols = null

  process: (data) ->
    try
      if not @protocols?
        if data.match(///^ [^\s{] ///)  # could use (https?|file):, but Safari sends (null) for the URL
          @emit 'oldproto'
          return
        else if message = @_parseMessage(data, ['hello'])
          if !message.protocols.length
            throw new ProtocolError("no protocols specified in handshake message")

          @protocols = {}
          if PROTOCOL_7 in message.protocols
            @protocols.monitoring = 7
          if CONN_CHECK in message.protocols
            @protocols.connCheck = 1
          if Object.keys(@protocols).length is 0
            throw new ProtocolError("no supported protocols found")
          @emit 'connected', @protocols
      else
        message = @_parseMessage(data, ['info'])
        @emit 'message', message
    catch e
      if e instanceof ProtocolError
        @emit 'error', e
      else
        throw e

  _parseMessage: (data, validCommands) ->
    try
      message = JSON.parse(data)
    catch e
      throw new ProtocolError('unparsable JSON', data)
    unless message.command
      throw new ProtocolError('missing "command" key', data)
    unless message.command in validCommands
      throw new ProtocolError("invalid command '#{message.command}', only valid commands are: #{validCommands.join(', ')})", data)
    return message
