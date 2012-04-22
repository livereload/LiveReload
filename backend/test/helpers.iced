fs           = require 'fs'
assert       = require 'assert'
Path         = require 'path'
Temp         = require 'temp'
MemoryStream = require 'memorystream'
WebSocket    = require 'ws'

{ EventEmitter }  = require 'events'

{ LRRoot } = require './helper'

DefaultWebSocketPort = parseInt(process.env['LRPortOverride'], 10) || 35729


exports.LRApplicationTestingHelper = class LRApplicationTestingHelper extends EventEmitter

  @initCommand: ->
    { resourcesDir: LRRoot, appDataDir: "/tmp", logDir: "/tmp", version: "1.2.3" }


  constructor: ->
    @input  = new MemoryStream()
    @output = new MemoryStream(null)
    @preferences = {}

    @_readyToQuit = no

    @reloadRequests = []


  run: (args, done) ->
    @application = require('../lib/livereload').run @input, @output, args, @quitHandler(done)
    @hook()
    @application


  hook: ->
    @output.on 'data', (message) =>
      console.error "Blow! '#{message}'"
      if message && ((typeof message) is 'object') && (message.constructor is Buffer)
        message = message.toString('utf8')
      return unless message.substr(0, 1) is '['
      message = JSON.parse message
      if message && ((typeof message) is 'object') && (message.constructor is Array)
        @handle message
      else
        throw new Error("Unexpected thingie sent by the backend: '#{JSON.stringify(message)}'")

  send: (command, arg) ->
    @input.write JSON.stringify([command, arg]) + "\n"

  handle: ([command, arg, cbid]) ->
    if @listeners(command).length > 0
      @emit arg, cbid
    else
      switch command
        when 'preferences.read'
          @send cbid, @preferences[arg.key] ? null
        when 'mainwnd.set_connection_status', 'workspace.set_monitoring_enabled', 'mainwnd.set_change_count', 'app.good_time_to_deliver_news'
          42  # nop
        when 'app.failedToStart'
          throw new Error("Exception thrown inside Node:\n" + arg.message)
        else
            throw new Error("Unexpected command sent by the backend: '#{command}'")


  sendAndWait: (command, arg, callback) ->
    executed = no
    timeout = null

    @application.rpc.once 'idle', (err) ->
      if timeout
        clearTimeout(timeout)
        timeout = null
      unless executed
        executed = yes
        callback(err)

    setTimeout ->
      timeout = null
      unless executed
        executed = yes
        callback(new Error("timeout"))
    , 500

    @send command, arg
    return


  readyToQuit: ->
    @_readyToQuit = yes

  quitHandler: (done) ->
    return (exitCode=0) =>
      unless @_readyToQuit
        assert no, "LiveReload has quit prematurely with exit code #{exitCode}"
      assert.equal exitCode, 0
      done()

  quit: ->
    @readyToQuit()
    @input.end()


  sendInitAndWait: (callback) ->
    @sendAndWait "app.init", LRApplicationTestingHelper.initCommand(), (err) =>
      assert.ifError err
      assert.ok @application.pluginManager?, "application.pluginManager is not initialized"
      assert.ok @application.pluginManager.plugins.length > 0, "application.pluginManager hasn't found any plugins"
      callback()

  runWithSingleProject: (done, projectMemento, callback) ->
    @folder = new TempFileSystemFolder()
    (@preferences['projects20a3'] = {})[@folder.path] = projectMemento

    @on 'monitoring.add', (arg) =>
      assert.equal arg.id, 'H1'
      assert.equal arg.path, @folder.path
    @on 'monitoring.remove', (arg) =>
      assert.equal arg.id, 'H1'

    @run [], done
    @sendInitAndWait callback

  generateChange: (fileName, content, callback) ->
    @folder.touch fileName, content
    @sendAndWait 'projects.changeDetected', { id: 'H1', changes: [fileName] }, =>
      setTimeout callback, 10

  simulateBrowserConnection: (callbacks, helloCallback=null) ->
    if helloCallback
      callbacks.hello = helloCallback

    ws = new WebSocket("ws://127.0.0.1:#{DefaultWebSocketPort}")
    ws.on 'open', =>
      ws.send JSON.stringify({ 'command': 'hello', 'protocols': ['http://livereload.com/protocols/official-7'] })
    ws.on 'message', (message) =>
      json = JSON.parse(message)
      if callback = callbacks[json.command]
        callback(json)
      else if json.command is 'hello'
        # ignore
      else if json.command is 'reload'
        @reloadRequests.push { path: Path.basename(json.path) }
      else
        throw new Error("Unexpected command received from the server: '#{json.command}'")



exports.TempFileSystemFolder = class TempFileSystemFolder

  constructor: ->
    @path = Temp.mkdirSync 'LRtest-'

  pathOf: (relativePath) ->
    Path.join(@path, relativePath)

  touch: (relativePath, content = "" + new Date()) ->
    fs.writeFileSync @pathOf(relativePath), content

  read: (relativePath) ->
    fs.readFileSync @pathOf(relativePath), 'utf8'
