assert = require 'assert'
Path   = require 'path'
fs     = require 'fs'

{ EventEmitter } = require 'events'

Project = require '../lib/projects/project'
TestVFS = require 'vfs-test'

DataDir = Path.join(__dirname, 'data')

readMementoSync = (name) -> JSON.parse(fs.readFileSync(Path.join(DataDir, name), 'utf8'))

class FakeSession
  findCompilerById: (compilerId) ->
    { id: compilerId }


describe "Project", ->

  it "should report basic info about itself", ->
    vfs = new TestVFS()
    session = new FakeSession()

    project = new Project(session, vfs, "/foo/bar")
    assert.equal project.name, 'bar'
    assert.equal project.path, '/foo/bar'
    assert.ok project.id =~ /^P\d+_bar$/


  it "should be able to load an empty memento", ->
    vfs = new TestVFS()
    session = new FakeSession()

    project = new Project(session, vfs, "/foo/bar")
    project.setMemento {}


  it "should be able to load a simple memento", ->
    vfs = new TestVFS()
    # vfs.put '/foo/bar/boz.css', "body: { background: red }\n"

    session = new FakeSession()

    project = new Project(session, vfs, "/foo/bar")
    project.setMemento { disableLiveRefresh: 1, compilationEnabled: 1 }


  it "should be able to load a real memento", ->
    vfs = new TestVFS()

    session = new FakeSession()

    project = new Project(session, vfs, "/foo/bar")
    project.setMemento readMementoSync('project_memento.json')

    assert.equal project.compilationEnabled, true
    assert.equal project.rubyVersionId, 'system'
