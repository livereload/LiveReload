fs           = require 'fs'
assert       = require 'assert'
Path         = require 'path'
Temp         = require 'temp'
MemoryStream = require 'memorystream'

{ EventEmitter }  = require 'events'

{ LRPluginsRoot } = require './helper'


exports.LRApplicationTestingHelper = class LRApplicationTestingHelper extends EventEmitter

  @initCommand: ->
    { pluginFolders: [LRPluginsRoot], preferencesFolder: "/ghi", version: "1.2.3" }


  constructor: ->
    @input  = new MemoryStream()
    @output = new MemoryStream(null)
    @preferences = {}

    @_readyToQuit = no


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


exports.TempFileSystemFolder = class TempFileSystemFolder

  constructor: ->
    @path = Temp.mkdirSync 'LRtest-'

  pathOf: (relativePath) ->
    Path.join(@path, relativePath)

  touch: (relativePath) ->
    fs.writeFileSync @pathOf(relativePath), "" + new Date()
