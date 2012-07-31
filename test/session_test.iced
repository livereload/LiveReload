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
