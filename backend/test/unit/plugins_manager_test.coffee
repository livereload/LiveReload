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
    assert.ok 'sass' of @manager.compilersById
    assert.ok 'compass' of @manager.compilersById
    assert.ok 'coffeescript' of @manager.compilersById
    assert.ok 'less' of @manager.compilersById
    assert.ok 'haml' of @manager.compilersById
