debug = require('debug')('livereload:tests')
assert = require 'assert'
Path   = require 'path'
fs     = require 'fs'

{ EventEmitter } = require 'events'

Session = require '../lib/session'
vfs = require 'vfs-local'

describe "livereload-core", ->

  pluginsDir = process.env.LRBundledPluginsOverride or throw new Error "Set LRBundledPluginsOverride env var to the real plugins path"
  unless fs.existsSync Path.join(pluginsDir, 'SASS.lrplugin/manifest.json')
    throw new Error "Provided LRBundledPluginsOverride path does not contain SASS.lrplugin"

  dataDir = Path.join(__dirname, 'data')


  o = (done, projectName, projMemento, func) ->
    session = new Session
    session.addPluginFolder pluginsDir

    sampleDir = Path.join(dataDir, projectName)

    memento = {}
    memento[sampleDir] = projMemento
    session.setProjectsMemento vfs, memento

    if func
      await func defer()

    session.queue.on 'empty', done
    session.queue.checkDrain()


  it "should not fuck up the initial analysis of less_with_imports", (done) ->
    o done, 'less_with_imports', {}
