assert    = require 'assert'
{ setup } = require '../helper'

describe "LR.app", ->
  beforeEach ->
    setup ['app']

  describe ".init", ->
    beforeEach ->
      LR.test.allow 'preferences.init', 'plugins.init', 'websockets.init', 'projects.init', 'stats.startup'

    describe "when called with correct arguments", ->
      beforeEach (done) ->
        LR.app.init { pluginFolders: ["/abc", "/def"], preferencesFolder: "/ghi", version: "1.2.3" }, done

      it "should initialize all other modules", ->
        assert.deepEqual LR.test.log, [
          ['preferences.init', "/ghi"]
          ['plugins.init', ["/abc", "/def"]]
          ['websockets.init']
          ['projects.init']
          ['stats.startup']
        ]

      it "should set LR.version to the version number sent by the server", ->
        assert.equal LR.version, "1.2.3"

    describe "when one of the initialization calls fails", ->
      beforeEach (done) ->
        LR.test.allow 'plugins.init', (_, __, callback) -> callback(new Error("simulated error"))
        LR.test.allow 'rpc.exit'
        LR.test.allowRPC 'app.failed_to_start'
        LR.app.init { pluginFolders: ["/abc", "/def"], preferencesFolder: "/ghi", version: "1.2.3" }, done

      it "should send failed_to_start message and exit", ->
        assert.deepEqual LR.test.log, [
          ['preferences.init', "/ghi"]
          ['C.app.failed_to_start', { message: "simulated error" }]
          ['rpc.exit', 1]
        ]
