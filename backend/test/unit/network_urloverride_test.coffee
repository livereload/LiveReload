assert = require 'assert'
Url    = require 'url'
wrap   = require '../wrap'

{ MockFS } = require '../mocks'

wsio = require 'websocket.io'
helper = require '../helper'

{ URLOverrideCoordinator, ERR_NOT_MATCHED, ERR_AUTH_FAILED, ERR_FILE_NOT_FOUND } = require '../../lib/network/urloverride'


describe "URLOverrideCoordinator", ->
  it "should agree to override CSS files", ->
    coordinator = new URLOverrideCoordinator()
    assert.ok coordinator.shouldOverrideFile('foo.css')

  it "should agree to override image files", ->
    coordinator = new URLOverrideCoordinator()
    assert.ok coordinator.shouldOverrideFile('foo.png')
    assert.ok coordinator.shouldOverrideFile('foo.jpg')
    assert.ok coordinator.shouldOverrideFile('foo.jpeg')
    assert.ok coordinator.shouldOverrideFile('foo.gif')

  it "shouldn't agree to override other files", ->
    coordinator = new URLOverrideCoordinator()
    assert.ok !coordinator.shouldOverrideFile('foo.php')
    assert.ok !coordinator.shouldOverrideFile('foo.less')

  it "should serve a simple overridden CSS file as is", (done) ->
    coordinator = new URLOverrideCoordinator()
    coordinator.Path = coordinator.fs = new MockFS('/foo/bar/boz.css', "Hello, world")

    url = coordinator.createOverrideURL('/foo/bar/boz.css')

    coordinator.handleHttpRequest Url.parse(url), (err, result) ->
      assert.equal err, null
      assert.equal result.content, "Hello, world"
      assert.equal result.mime, 'text/css'
      done()

  it "should absolutize referenced url()'s in the overridden CSS file", (done) ->
    coordinator = new URLOverrideCoordinator()
    coordinator.Path = coordinator.fs = new MockFS('/foo/bar/boz.css', "a { background: url(test.png) }")

    url = coordinator.createOverrideURL('/foo/bar/boz.css')

    coordinator.handleHttpRequest Url.parse(url + "?url=http://example.com/foo/bar.html", yes), (err, result) ->
      assert.equal err, null
      assert.equal result.content, "a { background: url(http://example.com/foo/test.png) }"
      assert.equal result.mime, 'text/css'
      done()

  it "should serve an overridden image file as is", (done) ->
    coordinator = new URLOverrideCoordinator()
    coordinator.Path = coordinator.fs = new MockFS('/foo/bar/boz.png', "PNG86 123")

    url = coordinator.createOverrideURL('/foo/bar/boz.png')

    coordinator.handleHttpRequest Url.parse(url), (err, result) ->
      assert.equal err, null
      assert.equal result.content, "PNG86 123"
      assert.equal result.mime, 'image/png'
      done()

  it "should return ERR_NOT_MATCHED when given a random URL", (done) ->
    coordinator = new URLOverrideCoordinator()

    coordinator.handleHttpRequest Url.parse("/foo/bar/boz.png"), (err, result) ->
      assert.equal err, ERR_NOT_MATCHED
      done()

  it "should return ERR_AUTH_FAILED when given a problematic URL", (done) ->
    coordinator = new URLOverrideCoordinator()

    url = coordinator.createOverrideURL('/foo/bar/boz.png')
    url = url.replace /[a-z0-9]{40}/, new Array(41).join('0')

    coordinator.handleHttpRequest Url.parse(url), (err, result) ->
      assert.equal err, ERR_AUTH_FAILED
      done()

  it "should return ERR_FILE_NOT_FOUND when the file is missing", (done) ->
    coordinator = new URLOverrideCoordinator()
    coordinator.Path = coordinator.fs = new MockFS('/empty.css', "")

    url = coordinator.createOverrideURL('/foo/bar/boz.png')

    coordinator.handleHttpRequest Url.parse(url), (err, result) ->
      assert.equal err, ERR_FILE_NOT_FOUND
      done()
