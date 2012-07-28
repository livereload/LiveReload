{ EventEmitter } = require 'events'


module.exports = class LRProtocolParser extends EventEmitter

  @ERR_DATA = ERR_DATA = 'DATA'
  @ERR_CMD  = ERR_CMD  = 'CMD'
  @ERR_ATTR = ERR_ATTR = 'ATTR'
  @ERR_NOPROTO = ERR_NOPROTO = 'NOPROTO'

  createError = (code, message) ->
    err = new Error(message)
    err.isLiveReloadProtocolError = yes
    err.code = code
    return err


  VALIDATORS =
    'required': (key, message) ->
      if typeof message[key] is 'undefined'
        throw createError(ERR_ATTR, "Required attribute '#{key}' is missing in command '#{message.command}'")

    'string': (key, message) ->
      return unless message.hasOwnProperty(key)
      if typeof message[key] isnt 'string'
        throw createError(ERR_ATTR, "Attribute '#{key}' must be a string, got #{typeof message[key]} in command '#{message.command}'")

    'boolean': (key, message) ->
      return unless message.hasOwnProperty(key)
      if typeof message[key] isnt 'boolean'
        throw createError(ERR_ATTR, "Attribute '#{key}' must be a boolean, got #{typeof message[key]} in command '#{message.command}'")

    'array': (key, message) ->
      return unless message.hasOwnProperty(key)
      if typeof message[key] isnt 'object' or !(message[key] instanceof Array)
        throw createError(ERR_ATTR, "Attribute '#{key}' must be an array, got #{typeof message[key]} in command '#{message.command}'")


  HANDSHAKE_COMMANDS =
    'hello':
      'protocols': ['required', 'array']
      'id':        ['string']
      'name':      ['string']
      'version':   ['string']
      '*':         []
  HANDSHAKE_PROTOCOL = { client_commands: HANDSHAKE_COMMANDS, server_commands: HANDSHAKE_COMMANDS }


  @protocols =
    CONN_CHECK_1:
      version: 1
      url: "http://livereload.com/protocols/connection-check-1"
      client_commands:
        'ping':
          'token': ['required', 'string']
        'pong':
          'token': ['required', 'string']
      server_commands:
        'ping':
          'token': ['required', 'string']
        'pong':
          'token': ['required', 'string']

    MONITORING_7:
      version: 7
      url: "http://livereload.com/protocols/official-7"
      client_commands:
        'info':
          'url': []
          'plugins': []
      server_commands:
        'reload':
          'path': ['required', 'string']
          'liveCSS': ['boolean']


  OPPOSITE_ROLES = { 'server': 'client', 'client': 'server' }


  constructor: (@role, @supportedProtocols) ->
    @peerRole = OPPOSITE_ROLES[@role]

    @supportedProtocolUrls = []
    for key in Object.keys(@supportedProtocols).sort()
      for proto in @supportedProtocols[key]
        @supportedProtocolUrls.push proto.url

    @reset()

  hello: ({ id, name, version }) ->
    throw new Error("ERR_INVALID_ARG: id is required") unless id
    throw new Error("ERR_INVALID_ARG: name is required") unless name
    throw new Error("ERR_INVALID_ARG: version is required") unless version
    {
      'command':   'hello'
      'protocols': @supportedProtocolUrls
      'id':        id
      'name':      name
      'version':   version
    }

  reset: ->
    @negotiatedProtocols = null
    @negotiatedProtocolDefinitions = [HANDSHAKE_PROTOCOL]

  received: (data) ->
    try
      message = JSON.parse(data)
    catch e
      @emit 'error', createError(ERR_DATA, "The received data is not a valid JSON message; is the client using the old protocol of LiveReload 1.x?")
      return

    try
      @_validate message, @peerRole
    catch e
      throw e unless e.isLiveReloadProtocolError
      @emit 'error', e
      return

    if message.command is 'hello'
      @_negotiate message.protocols
      if @negotiatedProtocolDefinitions.length is 0
        @emit 'error', createError(ERR_NOPROTO, "No supported protocols have been negotiated")
      else
        @emit 'connected', @negotiatedProtocols
    else
      @emit 'command', message

  sending: (message) ->
    # we might be sending our HELLO after receiving an incoming one
    return if message.command is 'hello'

    @_validate message, @role
    return

  _negotiate: (proposedProtocols) ->
    @negotiatedProtocols = {}
    @negotiatedProtocolDefinitions = []
    for own key, versions of @supportedProtocols
      for proto in versions
        if proto.url in proposedProtocols
          @negotiatedProtocols[key] = proto.version
          @negotiatedProtocolDefinitions.push proto
          break

  _validate: (message, role) ->
    unless typeof message.command is 'string'
      throw createError(ERR_DATA, "The JSON message is missing a 'command' key")

    validCommand = no
    validAttrs = []

    for proto in @negotiatedProtocolDefinitions
      commands = proto["#{role}_commands"]
      if commands.hasOwnProperty(message.command)
        validCommand = yes
        for own attr, validators of commands[message.command]
          for validator in validators
            VALIDATORS[validator](attr, message)
          validAttrs.push attr

    unless validCommand
      throw createError(ERR_CMD, "Invalid command '#{message.command}'")

    for attr in Object.keys(message) when attr isnt 'command'
      unless attr in validAttrs or '*' in validAttrs
        throw createError(ERR_ATTR, "Invalid attribute '#{attr}' in command '#{message.command}'")

