assert = require 'assert'
Path   = require 'path'
wrap   = require '../wrap'

LRPluginManager = require '../../lib/plugins/manager'
{ LRPluginsRoot } = require '../helper'


describe "LRPluginManager", ->

  beforeEach wrap (done) ->
    @manager = new LRPluginManager([LRPluginsRoot])
    @manager.rescan (err) =>
      assert.equal err, null
      done()

  it "should be able to find standard plugins", wrap ->
    assert.equal @manager.plugins.length, 9

  it "should be able to find all standard compilers", wrap ->
    assert.ok 'SASS' of @manager.compilers
    assert.ok 'Compass' of @manager.compilers
    assert.ok 'CoffeeScript' of @manager.compilers
    assert.ok 'LESS' of @manager.compilers
    assert.ok 'HAML' of @manager.compilers
