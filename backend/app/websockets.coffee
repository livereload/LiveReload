wsio = require 'websocket.io'
http = require 'http'
Url  = require 'url'
Path = require 'path'
fs   = require 'fs'

{ Parser, PROTOCOL_7, CONN_CHECK } = require '../lib/protocol'

Version = '2.0.4'
HandshakeTimeout = 1000
Port = 35729


_server      = null
_wsserver    = null
_connections = {}
_nextConnectionId = 1


class Connection
  constructor: (@socket) ->
    @id = "C" + (_nextConnectionId++)

    @socket.on 'message', @_ondata.bind(@)
    @socket.on 'close',   @_onclose.bind(@)

    @parser = new Parser
    @parser.on 'connected', @_onHandshakeDone.bind(@)
    @parser.on 'message',   @_oncommand.bind(@)
    @parser.on 'error',     @_onerror.bind(@)

    @handshakeTimeout = setTimeout(@_onHandshakeTimeout.bind(@), HandshakeTimeout)

    @send {
      command:    "hello"
      protocols:  [PROTOCOL_7, CONN_CHECK]
      serverName: "LiveReload 2"
    }

  send: (command) ->
    payload = JSON.stringify(command)
    LR.log.fyi "Sending message #{payload}"
    @socket.send payload

  _ondata: (payload) ->
    LR.log.fyi "Got message #{payload}"
    @parser.process(payload)

  _onclose: (e) ->
    @_cancelHandshakeTimeout()
    delete _connections[@id]
    console.log "Closed"

  _onerror: (err) ->
    LR.log.wtf "Web Socket communication error: #{err.message}"
    @socket.close()

  _onHandshakeTimeout: ->
    @handshakeTimeout = null
    LR.log.wtf "Web Socket handshake timeout"
    @socket.close()

  _cancelHandshakeTimeout: ->
    if @handshakeTimeout
      clearTimeout @handshakeTimeout
      @handshakeTimeout = null

  _onHandshakeDone: ->
    @_cancelHandshakeTimeout()
    _connections[@id] = this
    LR.log.wtf "Web Socket handshake done, connected."

  _oncommand: (command) ->
    LR.log.fyi "Ignoring command #{command.command}"


exports.init = (callback) ->
  _server = http.createServer()
  _server.listen Port, (err) ->
    return callback(err) if err

    _server.on 'request', (request, response) ->
      request.on 'end', ->
        path = Url.parse(request.url).pathname
        if path.match ///^ /x?livereload\.js $///
          data = fs.readFileSync(Path.join(__dirname, '../res/livereload.js'))
          response.writeHead 200, 'Content-Length': data.length, 'Content-Type': 'text/javascript'
          response.end(data)
        else
          response.writeHead 404
          response.end()

    _wsserver = wsio.attach(_server)

    _wsserver.on 'connection', (socket) ->
      new Connection(socket)

    callback()


exports.sendReloadCommand = ({ path }) ->
  for own dummy, connection of _connections
    connection.send {
      command: 'reload'
      path:    path
      liveCSS: yes
    }
