fs   = require 'fs'
Path = require 'path'

{ LRWebSocketServer } = require '../lib/network/server'

ResourceFolder = Path.join(__dirname, '../res')

class LRWebSocketController

  constructor: ->
    @server = new LRWebSocketServer()
    @server.on 'httprequest', @_onhttprequest.bind(@)

    @server.on 'wsconnected',    @_updateConnectionCountInUI.bind(@)
    @server.on 'wsdisconnected', @_updateConnectionCountInUI.bind(@)

    @server.on 'wscommand', (connection) =>
      # TODO: handle INFO command?

    @changeCount = 0

  init: (callback) ->
    @server.start =>
      LR.log.fyi "WebSocket server listening on port #{@server.port}."
      callback(null)

  sendReloadCommand: ({ path, originalPath, liveCSS, enableOverride }) ->
    for connection in @server.monitoringConnections()
      connection.send {
        command: 'reload'
        path:    path
        originalPath: originalPath
        liveCSS: liveCSS
        # overrideURL: ...
      }

    @changeCount += 1
    @_updateChangeCountInUI()

  monitoringConnectionCount: -> @server.monitoringConnectionCount()

  _updateConnectionCountInUI: ->
    LR.client.mainwnd.setConnectionStatus connectionCount: @monitoringConnectionCount()
    LR.client.workspace.setMonitoringEnabled (@monitoringConnectionCount() > 0)

  _updateChangeCountInUI: ->
    LR.client.mainwnd.setChangeCount changeCount: @changeCount

  _onhttprequest: (url, request, response) ->
    if url.pathname.match ///^ /x?livereload\.js $///
      data = fs.readFileSync(Path.join(ResourceFolder, 'livereload.js'))
      response.writeHead 200, 'Content-Length': data.length, 'Content-Type': 'text/javascript'
      response.end(data)
    else
      response.writeHead 404
      response.end()


_controller = new LRWebSocketController()

exports.init = (cb) -> _controller.init(cb)

exports.api =
  sendReloadCommand: (arg, callback) ->
    _controller.sendReloadCommand(arg)
    callback(null)
