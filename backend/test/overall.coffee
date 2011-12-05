require 'sugar'
assert = require 'assert'

{ CommunicatorTwin, LRPluginsRoot } = require './helper'


describe "Back-end", ->
  describe "when given init command", ->
    it "should execute it", (done) ->
      communicator = new CommunicatorTwin()
      communicator.on 'end', ->
        assert.equal communicator.toString(), """{"command":"init.ok"}\n"""
        done()
      communicator.send 'init', pluginFolders: [LRPluginsRoot], ->
        communicator.end()
