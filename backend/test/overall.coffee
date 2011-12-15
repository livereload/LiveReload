require 'sugar'
assert = require 'assert'

{ CommunicatorTwin, LRPluginsRoot } = require './helper'
{ createTestEnvironment } = require '../config/env'

describe "Back-end", ->
  before ->
    global.LR = createTestEnvironment()

  describe "when given init command", ->

    it "should invoke C.mainwnd.set_project_list", (done) ->
      called = no
      LR.client.mount 'mainwnd.set_project_list', ->
        called = yes

      LR.app.init { pluginFolders: [LRPluginsRoot] }, (err) ->
        assert.ok called
        done(err)
