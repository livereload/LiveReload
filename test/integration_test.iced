debug = require('debug')('livereload:tests')
Path   = require 'path'
fs     = require 'fs'
scopedfs = require 'scopedfs'

{ ok, equal, ifError } = require 'assert'

{ EventEmitter } = require 'events'

{ Session, R } = require "../#{process.env.JSLIB or 'lib'}/session"
vfs = require 'vfs-local'


pluginsDir = process.env.LRBundledPluginsOverride or throw new Error "Set LRBundledPluginsOverride env var to the real plugins path"
unless fs.existsSync Path.join(pluginsDir, 'SASS.lrplugin/manifest.json')
  throw new Error "Provided LRBundledPluginsOverride path does not contain SASS.lrplugin"


dataDir = Path.join(__dirname, 'data')


_lastContext = null
class TestContext
  constructor: ->
    if _lastContext
      try _lastContext.close()
    _lastContext = this

    @universe = new R.Universe()
    @session = @universe.create(Session)
    @session.addPluginFolder pluginsDir

  createProject: (projectName, projMemento) ->
    @projfs = projfs = scopedfs.scoped(Path.join(dataDir, projectName))

    memento = {}
    memento[projfs.path] = projMemento
    @session.setProjectsMemento vfs, memento

  close: ->
    @session?.close()

afterEach ->
  if _lastContext
    _lastContext.close()
    _lastContext = null


describe "livereload-core", ->

  it "should not fuck up the initial analysis of less_with_imports", (done) ->
    c = new TestContext()
    c.createProject('less_with_imports', {})
    c.session.after(done, 'done')


  it "should compile test.less based on an external change event", (done) ->
    c = new TestContext()
    c.createProject('less', { compilationEnabled: yes })
    await c.session.after defer(), 'test.after.createProject'

    cssFile = c.projfs.pathOf('test.css')
    await fs.unlink cssFile, defer()

    runs = c.session.handleChange vfs, c.projfs.path, ['test.less']
    equal runs.length, 1
    await c.session.after defer(), 'test.after.handleChange'

    await fs.readFile cssFile, 'utf8', defer(err, css)
    ok !err, "Compiled CSS file does not exist: #{cssFile}"
    ok css.match /red/
    await fs.unlink cssFile, defer()

    c.session.after(done, 'done')


  it "should save and restore a memento of a project", (done) ->
    c = new TestContext()
    c.createProject('less', { compilationEnabled: yes })
    await c.session.after defer()

    await c.session.makeProjectsMemento defer(err, memento)
    ifError err
    c.close()

    console.log "memento = %j", memento

    c = new TestContext()
    c.session.setProjectsMemento vfs, memento

    done()


      # cssFile = Path.join(c.projfs.path, 'test.css')
      # await fs.unlink cssFile, defer()

      # runs = c.session.handleChange vfs, c.projfs.path, ['test.less']
      # equal runs.length, 1
      # await c.session.queue.on 'empty', defer()

      # await fs.readFile cssFile, 'utf8', defer(err, css)
      # ok !err, "Compiled CSS file does not exist: #{cssFile}"
      # ok css.match /red/
      # await fs.unlink cssFile, defer()

      # callback()
