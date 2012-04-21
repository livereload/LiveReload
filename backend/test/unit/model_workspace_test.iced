fs     = require 'fs'
assert = require 'assert'
wrap   = require '../wrap'

helper = require '../helper'

LRWorkspace = require '../../lib/model/workspace'


describe "LRWorkspace", ->
  it "should load a real-world memento", ->
    LR.fsmanager = new (require '../../lib/vfs/fsmanager')()
    LR.pluginManager =
      compilersById: {}
    memento = JSON.parse(fs.readFileSync(__filename.replace /\.\w+$/, '.json', 'utf8'))
    workspace = new LRWorkspace(memento)
    assert.equal workspace.projects.length, 11
