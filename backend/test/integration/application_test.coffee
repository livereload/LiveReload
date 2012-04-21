assert = require 'assert'
http   = require 'http'
wrap   = require '../wrap'

LRApplication = require '../../lib/app/application'

{ MockRpcTransport }           = require '../mocks'
{ LRApplicationTestingHelper, TempFileSystemFolder } = require '../helpers'
{ LRPluginsRoot }              = require '../helper'


describe "LiveReload", ->

  it "should start up with a mock transport and direct invocation of start()", (done) ->
    application = new LRApplication(new MockRpcTransport())

    helper = new LRApplicationTestingHelper()
    helper.send = (command, arg) => application.rpc.transport.simulate [command, arg]
    application.rpc.transport.on 'sent', (message) => helper.handle message

    application.start LRApplicationTestingHelper.initCommand(), (err) ->
      assert.ifError err
      assert.ok application.pluginManager?, "application.pluginManager is not initialized"
      assert.ok application.pluginManager.plugins.length > 0, "application.pluginManager hasn't found any plugins"

      application.once 'quit', done
      application.rpc.transport.emit 'end'


  it "should start up in --console mode", (done) ->
    helper = new LRApplicationTestingHelper()
    helper.run ['--console'], done
    helper.sendInitAndWait =>
      helper.quit()


  it "should start up normally, execute the initialization command and then quit", (done) ->
    helper = new LRApplicationTestingHelper()
    helper.run [], done
    helper.sendInitAndWait =>
      helper.quit()


  it "should serve livereload.js after startup", (done) ->
    WebSocket = require 'ws'
    DefaultWebSocketPort = parseInt(process.env['LRPortOverride'], 10) || 35729

    helper = new LRApplicationTestingHelper()
    helper.run [], done
    helper.sendInitAndWait =>
      http.get { host: '127.0.0.1', port: DefaultWebSocketPort, path: '/livereload.js' }, (res) =>
        assert.equal res.statusCode, 200
        res.setEncoding 'utf8'
        data = []
        res.on 'data', (chunk) => data.push chunk
        res.on 'end', =>
          data = data.join('')
          assert.ok data.match(/LR-verbose/)
          helper.quit()


  it "should listen to web socket connections after startup", (done) ->
    WebSocket = require 'ws'
    DefaultWebSocketPort = parseInt(process.env['LRPortOverride'], 10) || 35729

    helper = new LRApplicationTestingHelper()
    helper.run [], done
    helper.sendInitAndWait =>
      ws = new WebSocket("ws://127.0.0.1:#{DefaultWebSocketPort}")
      ws.on 'open', ->
        ws.send JSON.stringify({ 'command': 'hello', 'protocols': ['http://livereload.com/protocols/official-7'] })
      ws.on 'message', (message) ->
        json = JSON.parse(message)
        if json.command is 'hello'
          helper.quit()


  it "should send 'app.failedToStart' when there's an error on startup", (done) ->
    helper = new LRApplicationTestingHelper()
    helper.application = new LRApplication(new MockRpcTransport())

    helper.application.on 'quit', (exitCode=0) =>
      assert.equal exitCode, 0
      done()

    helper.application.on 'init', (callback) -> callback(new Error("simulated error"))

    helper.application.rpc.transport.on 'sent', ([command, arg]) =>
      if command is 'app.failedToStart'
        helper.readyToQuit()

    helper.application.rpc.transport.simulate LRApplicationTestingHelper.initCommand()


  it "should tell the browser to reload when a monitored project has been changed", (done) ->
    WebSocket = require 'ws'
    DefaultWebSocketPort = parseInt(process.env['LRPortOverride'], 10) || 35729

    folder = new TempFileSystemFolder()
    reloadRequests = []

    helper = new LRApplicationTestingHelper()
    helper.on 'monitoring.add', (arg) =>
      assert.equal arg.id, 'H1'
      assert.equal arg.path, folder.path
    helper.on 'monitoring.remove', (arg) =>
      assert.equal arg.id, 'H1'

    (helper.preferences['projects20a3'] = {})[folder.path] = { 'enabled2': yes }

    produceFakeChange = ->
      folder.touch 'foo.html'
      helper.sendAndWait 'projects.changeDetected', { id: 'H1', changes: ['foo.html'] }, ->
        setTimeout ->
          assert.deepEqual reloadRequests, [ { path: 'foo.html' } ]
          helper.quit()
        , 10

    helper.run [], done
    helper.sendInitAndWait =>
      ws = new WebSocket("ws://127.0.0.1:#{DefaultWebSocketPort}")
      ws.on 'open', ->
        ws.send JSON.stringify({ 'command': 'hello', 'protocols': ['http://livereload.com/protocols/official-7'] })
      ws.on 'message', (message) ->
        json = JSON.parse(message)
        if json.command is 'hello'
          produceFakeChange()
        else if json.command is 'reload'
          reloadRequests.push { path: json.path }
