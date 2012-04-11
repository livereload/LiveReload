assert = require 'assert'
http   = require 'http'
wrap   = require '../wrap'

LRApplication = require '../../lib/app/application'

{ MockRpcTransport }           = require '../mocks'
{ LRApplicationTestingHelper } = require '../helpers'
{ LRPluginsRoot }              = require '../helper'


describe "LiveReload", ->

  it "should start up with a mock transport and direct invocation of start()", (done) ->
    application = new LRApplication(new MockRpcTransport())

    application.start { pluginFolders: [LRPluginsRoot], preferencesFolder: "/ghi", version: "1.2.3" }, (err) ->
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
