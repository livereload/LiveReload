debug = require('debug')('livereload:tests')
Path   = require 'path'
fs     = require 'fs'

{ ok, equal } = require 'assert'

{ EventEmitter } = require 'events'

{ Session, R } = require "../#{process.env.JSLIB or 'lib'}/session"
vfs = require 'vfs-local'

describe "livereload-core", ->

  pluginsDir = process.env.LRBundledPluginsOverride or throw new Error "Set LRBundledPluginsOverride env var to the real plugins path"
  unless fs.existsSync Path.join(pluginsDir, 'SASS.lrplugin/manifest.json')
    throw new Error "Provided LRBundledPluginsOverride path does not contain SASS.lrplugin"

  dataDir = Path.join(__dirname, 'data')


  o = (done, projectName, projMemento, func) ->
    universe = new R.Universe()
    session = universe.create(Session)
    session.addPluginFolder pluginsDir

    sampleDir = Path.join(dataDir, projectName)

    memento = {}
    memento[sampleDir] = projMemento
    session.setProjectsMemento vfs, memento

    if func
      context = { session, root: sampleDir }
      await func.call context, defer()

    session.queue.on 'empty', done
    session.queue.checkDrain()


  it "should not fuck up the initial analysis of less_with_imports", (done) ->
    o done, 'less_with_imports', {}

  it "should compile test.less", (done) ->
    o done, 'less', { compilationEnabled: yes }, (callback) ->
      cssFile = Path.join(@root, 'test.css')
      await fs.unlink cssFile, defer()

      runs = @session.handleChange vfs, @root, ['test.less']
      equal runs.length, 1
      await @session.queue.on 'empty', defer()

      await fs.readFile cssFile, 'utf8', defer(err, css)
      ok !err, "Compiled CSS file does not exist: #{cssFile}"
      ok css.match /red/
      await fs.unlink cssFile, defer()

      callback()
