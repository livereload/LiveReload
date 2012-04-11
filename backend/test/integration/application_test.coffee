assert       = require 'assert'
wrap         = require '../wrap'

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
