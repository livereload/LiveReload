assert       = require 'assert'
MemoryStream = require 'memorystream'

{ LRPluginsRoot } = require './helper'


exports.LRApplicationTestingHelper = class LRApplicationTestingHelper

  @initCommand: ->
    { pluginFolders: [LRPluginsRoot], preferencesFolder: "/ghi", version: "1.2.3" }

  constructor: ->
    @input  = new MemoryStream()
    @output = new MemoryStream(null, readable: no)

    @_readyToQuit = no


  run: (args, done) ->
    @application = require('../lib/livereload').run @input, @output, args, @quitHandler(done)


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

    @input.write JSON.stringify([command, arg]) + "\n"
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
