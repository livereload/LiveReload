assert = require 'assert'

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

