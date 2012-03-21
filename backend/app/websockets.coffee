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

    @server.on 'wsoldproto', (connection) =>
      LR.app.displayHelpfulWarning
        title:  "Legacy browser extensions"
        text:   "LiveReload browser extensions 1.x are no longer supported and won't work with LiveReload 2.\n\nPlease update your browser extensions to version 2.x to get advantage of many bug fixes, automatic reconnection, @import support, in-browser LESS.js support and more."
        button: "Update Now"
        url:    "http://help.livereload.com/kb/general-use/browser-extensions"
        # TODO:
        # browserId: "com.apple.Safari" or "com.google.Chrome" or "org.mozilla.firefox"

    @changeCount = 0

  init: (callback) ->
    @server.start (err) =>
      if err
        if err.code && err.code == 'EADDRINUSE'
          LR.app.displayCriticalError
            title: "Failed to start: port occupied"
            text:  "LiveReload cannot listen on port #{@server.port}. You probably have another copy of LiveReload 2.x, a command-line LiveReload 1.x or an alternative tool like guard-livereload running.\n\nPlease quit any other live reloaders and rerun LiveReload."
            url:   'http://help.livereload.com/kb/troubleshooting/failed-to-start-port-occupied'
          return callback(null)
        else
          return callback(err)

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

    if @monitoringConnectionCount() > 0
      LR.client.app.goodTimeToDeliverNews()

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
