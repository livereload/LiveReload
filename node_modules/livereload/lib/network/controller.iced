debug = require('debug')('livereload:websockets')
fs   = require 'fs'
Path = require 'path'

LRWebSocketServer = require 'livereload-server'
{ URLOverrideCoordinator, ERR_NOT_MATCHED, ERR_AUTH_FAILED, ERR_FILE_NOT_FOUND } = require './urloverride'

ResourceFolder = Path.join(__dirname, '../../res')

module.exports =
class LRWebSocketController

  constructor: (@context) ->
    @session = @context.session

    @session.on 'browser-command', (command) =>
      @sendReloadCommand(command)

    @server = new LRWebSocketServer
      port: +process.env['LRPortOverride'] || null

      protocols:
        saving: 1

      id: "com.livereload.LiveReload"
      name: "LiveReload"
      version: "3.0.0"

    @server.on 'httprequest', @_onhttprequest.bind(@)

    @server.on 'connected',    @_updateConnectionCountInUI.bind(@)
    @server.on 'disconnected', @_updateConnectionCountInUI.bind(@)

    @server.on 'command', (connection, message) =>
      @session.execute message, connection, (err) =>
        console.error err.stack if err

    @server.on 'livereload.js', (req, res) =>
      console.log "Serving livereload.js."
      await fs.readFile Path.join(ResourceFolder, 'livereload.js'), 'utf8', defer(err, data)
      throw err if err
      res.writeHead 200, 'Content-Length': data.length, 'Content-Type': 'text/javascript'
      res.end(data)

    @server.on 'error', (err, connection) =>
      LR.app.displayHelpfulWarning
        title:  "Legacy browser extensions"
        text:   "LiveReload browser extensions 1.x are no longer supported and won't work with LiveReload 2.\n\nPlease update your browser extensions to version 2.x to get advantage of many bug fixes, automatic reconnection, @import support, in-browser LESS.js support and more."
        button: "Update Now"
        url:    "http://help.livereload.com/kb/general-use/browser-extensions"
        # TODO:
        # browserId: "com.apple.Safari" or "com.google.Chrome" or "org.mozilla.firefox"

    @changeCount = 0

    @urlOverrideCoordinator = new URLOverrideCoordinator()

    @monitoringCessationTimer = null
    @monitoringCessationTimeout = 30000

  init: (callback) ->
    @server.listen (err) =>
      if err
        if err.code && err.code == 'EADDRINUSE'
          LR.app.displayCriticalError
            title: "Failed to start: port occupied"
            text:  "LiveReload tried to listen on port #{@server.port}, but it was occupied by another app.\n\nThe following tools are incompatible with LiveReload: guard-livereload; rack-livereload; Sublime Text LiveReload plugin; any other tools that use LiveReload browser extensions.\n\nPlease make sure you're not running any of those tools, and restart LiveReload. If in doubt, contact support@livereload.com."
            url:   'http://help.livereload.com/kb/troubleshooting/failed-to-start-port-occupied'
          return callback(null)
        else
          return callback(err)

      debug "WebSocket server listening on port #{@server.port}."
      callback(null)

  sendReloadCommand: (message) ->
    if message.enableOverride and @urlOverrideCoordinator.shouldOverrideFile(path)
      message.overrideURL = @urlOverrideCoordinator.createOverrideURL(path)
      delete message.enableOverride

    for connection in @server.monitoringConnections()
      connection.send message

    @changeCount += 1
    @_updateChangeCountInUI()

    if @monitoringConnectionCount() > 0
      LR.client.app.goodTimeToDeliverNews()

  monitoringConnectionCount: -> @server.monitoringConnectionCount()

  _updateConnectionCountInUI: ->
    # LR.client.mainwnd.setConnectionStatus connectionCount: @monitoringConnectionCount()
    LR.projects.setConnectionStatus       connectionCount: @monitoringConnectionCount()

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
    # LR.client.mainwnd.setChangeCount changeCount: @changeCount

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
            debug "ERROR: Error processing URL override HTTP request: #{e.message || e}"
            response.writeHead 500
            response.end("Error processing this request. Please see the log file, and try reloading this page.")
        else
          response.setHeader 'Content-Type',   result.mime
          response.setHeader 'Content-Length', result.content.length
          response.end result.content
