fs   = require 'fs'
Path = require 'path'

{ LRWebSocketServer } = require '../lib/network/server'
{ URLOverrideCoordinator, ERR_NOT_MATCHED, ERR_AUTH_FAILED, ERR_FILE_NOT_FOUND } = require '../lib/network/urloverride'

ResourceFolder = Path.join(__dirname, '../res')

class LRWebSocketController

  constructor: ->
    @server = new LRWebSocketServer(port: +process.env['LRPortOverride'] || null)
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

    @server.on 'error', (err) => @_handleServerError(err)

    @changeCount = 0

    @urlOverrideCoordinator = new URLOverrideCoordinator()

    @monitoringCessationTimer = null
    @monitoringCessationTimeout = 30000

  init: (callback) ->
    @server.start (err) =>
      if err
        return @_handleServerError err, callback

      LR.log.fyi "WebSocket server listening on port #{@server.port}."
      callback(null)

  _handleServerError: (err, callback=@_throwServerError.bind(@)) ->
    if err.code && err.code == 'EADDRINUSE'
      LR.app.displayCriticalError
        title: "Failed to start: port occupied"
        text:  "LiveReload cannot listen on port #{@server.port}. You probably have another copy of LiveReload 2.x, a command-line LiveReload 1.x or an alternative tool like guard-livereload running.\n\nPlease quit any other live reloaders and rerun LiveReload."
        url:   'http://help.livereload.com/kb/troubleshooting/failed-to-start-port-occupied'
      return callback(null)

    return callback(err)

  _throwServerError: (err) ->
    if err
      throw err

  sendReloadCommand: ({ path, originalPath, liveCSS, enableOverride }) ->
    for connection in @server.monitoringConnections()
      message =
        command: 'reload'
        path:    path
        originalPath: originalPath
        liveCSS: liveCSS

      if enableOverride and @urlOverrideCoordinator.shouldOverrideFile(path)
        message.overrideURL = @urlOverrideCoordinator.createOverrideURL(path)

      connection.send message

    @changeCount += 1
    @_updateChangeCountInUI()

    if @monitoringConnectionCount() > 0
      LR.client.app.goodTimeToDeliverNews()

  monitoringConnectionCount: -> @server.monitoringConnectionCount()

  _updateConnectionCountInUI: ->
    LR.client.mainwnd.setConnectionStatus connectionCount: @monitoringConnectionCount()

    if @monitoringConnectionCount() > 0
      LR.client.workspace.setMonitoringEnabled yes
      if @monitoringCessationTimer
        clearTimeout(@monitoringCessationTimer)
        @monitoringCessationTimer = null
    else
      unless @monitoringCessationTimer
        @monitoringCessationTimer = setTimeout =>
          LR.client.workspace.setMonitoringEnabled no
          @monitoringCessationTimer = null
        , @monitoringCessationTimeout


  _updateChangeCountInUI: ->
    LR.client.mainwnd.setChangeCount changeCount: @changeCount

  _onhttprequest: (url, request, response) ->
    if url.pathname.match ///^ /x?livereload\.js $///
      data = fs.readFileSync(Path.join(ResourceFolder, 'livereload.js'))
      response.writeHead 200, 'Content-Length': data.length, 'Content-Type': 'text/javascript'
      response.end(data)
    else
      @urlOverrideCoordinator.handleHttpRequest url, (err, result) ->
        if err
          if err is ERR_NOT_MATCHED
            response.writeHead 404
            response.end()
          else if err is ERR_AUTH_FAILED
            response.writeHead 403
            response.end("LiveReload cannot authenticate this request; please reload the page. (Happens if you restart LiveReload app.)")
          else if err is ERR_FILE_NOT_FOUND
            response.writeHead 404
            response.end("The given file no longer exists. Please reload the page.")
          else
            LR.omg "Error processing URL override HTTP request: #{e.message || e}"
            response.writeHead 500
            response.end("Error processing this request. Please see the log file, and try reloading this page.")
        else
          response.setHeader 'Content-Type',   result.mime
          response.setHeader 'Content-Length', result.content.length
          response.end result.content


_controller = new LRWebSocketController()

exports.init = (cb) -> _controller.init(cb)

exports.api =
  sendReloadCommand: (arg, callback) ->
    _controller.sendReloadCommand(arg)
    callback(null)
