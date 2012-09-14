assert = require 'assert'

{ EventEmitter } = require 'events'

Session = require '../lib/session'
TestVFS = require 'vfs-test'

describe "Session", ->

  it "should monitor the added projects and issue reload requests", (done) ->
    vfs = new TestVFS
    vfs.put '/foo/bar/boz.css', "body: { background: red }\n"

    session = new Session
    session.addProject vfs, '/foo/bar'

    session.on "command", (message) ->
      assert.equal message.command, 'reload'
      assert.equal message.path, '/foo/bar/boz.css'
      session.close()
      done()

    session.startMonitoring()
    vfs.put '/foo/bar/boz.css', "body: { background: green }\n"


  it "should implement addInterface", ->
    face = new EventEmitter()
    session = new Session
    session.addInterface(face)
    assert.equal face.listeners('command').length, 1


  it "should be able to load a memento", ->
    session = new Session
    vfs = new TestVFS
    session.setProjectsMemento vfs, {
      '/foo/bar': { compilationEnabled: 1 }
      '/foo/boz': { compilationEnabled: 0 }
    }

    assert.equal session.projects.length, 2

    bar = session.findProjectByPath('/foo/bar')
    assert.ok bar?
    assert.equal bar.compilationEnabled, true

    boz = session.findProjectByPath('/foo/boz')
    assert.ok boz?
    assert.equal boz.compilationEnabled, false


  it "should handle 'save' command", (done) ->
    vfs = new TestVFS()
    vfs.put '/foo/bar/app/static/test.css', "h1 { color: red }\n"

    session = new Session
    session.setProjectsMemento vfs, {
      '/foo/bar': { urls: ['example.com'] }
    }
    session.addProject vfs, '/foo/bar'

    session.execute { command: 'save', url: 'http://example.com/static/test.css', content: "h1 { color: green }\n" }, null, (err) ->
      assert.ifError err
      assert.equal vfs.get('/foo/bar/app/static/test.css'), "h1 { color: green }\n"
      done()


  it "should involve postproc plugin when loading a memento", ->
    session = new Session
    vfs = new TestVFS
    session.setProjectsMemento vfs, {
      '/foo/bar': { postproc: 'foo' }
    }

    bar = session.findProjectByPath('/foo/bar')
    assert.ok bar?
    assert.equal bar.postprocCommand, 'foo'
    assert.equal bar.postprocLastRunTime, 0


  it "should handle changes", ->
    session = new Session
    vfs = new TestVFS
    session.setProjectsMemento vfs, {
      '/foo/bar': {}
    }

    bar = session.findProjectByPath('/foo/bar')
    assert.ok bar?

    runs = session.handleChange vfs, ['/foo/bar/boz.js']
    assert.equal runs.length, 1
    assert.equal runs[0].project, bar

    requests = session.queue.getQueuedRequests()
    assert.equal requests.length, 1, "Requests.length != 1: #{JSON.stringify(requests)}"
    assert.equal requests[0].project, runs[0].project.id
    assert.equal requests[0].action, 'postproc'
