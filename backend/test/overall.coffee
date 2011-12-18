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

      LR.app.init { pluginFolders: [LRPluginsRoot], preferencesFolder: process.env['TMPDIR'] }, (err) ->
        assert.equal err, null
        assert.ok called
        done(err)

  it "can use preferences", (done) ->
    LR.preferences.init process.env['TMPDIR'], ->
      LR.preferences.set 'foo.bar', 42, ->
        LR.preferences.get 'foo.bar', (value) ->
          assert.equal value, 42
          setTimeout done, 200
