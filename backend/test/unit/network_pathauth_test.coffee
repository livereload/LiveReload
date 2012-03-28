assert = require 'assert'
wrap   = require '../wrap'

wsio = require 'websocket.io'
helper = require '../helper'

{ PathAuthenticator } = require '../../lib/network/pathauth'


describe "PathAuthenticator", ->
  it "should produce url path that starts with a predefined prefix", ->
    authenticator = new PathAuthenticator()
    urlPath = authenticator.urlPathForServingLocalPath('/foo/bar')
    assert.ok urlPath.match ///^ /_livereload/url-override-v1/ ///

  it "should produce url path that includes the local path", ->
    authenticator = new PathAuthenticator()
    urlPath = authenticator.urlPathForServingLocalPath('/foo/bar')
    assert.ok urlPath.indexOf('/foo/bar') != -1

  it "should return 404 error for malformed paths", ->
    authenticator = new PathAuthenticator()
    [errCode, localPath] = authenticator.localPathForUrlPath('/foo/bar')

    assert.equal errCode, 404
    assert.ok !localPath

  it "should agree to serve the produced url path", ->
    authenticator = new PathAuthenticator()
    urlPath = authenticator.urlPathForServingLocalPath('/foo/bar')
    [errCode, localPath] = authenticator.localPathForUrlPath(urlPath)

    assert.equal errCode, 200
    assert.equal localPath, '/foo/bar'

  it "shouldn't agree to serve a different url path", ->
    authenticator = new PathAuthenticator()
    urlPath = authenticator.urlPathForServingLocalPath('/foo/bar')
    urlPath = urlPath.replace '/foo/bar', '/foo/boz'
    [errCode, localPath] = authenticator.localPathForUrlPath(urlPath)

    assert.equal errCode, 403
    assert.ok !localPath

  it "shouldn't serve a URL path signed with another instance of the class", ->
    authenticator = new PathAuthenticator()
    urlPath = authenticator.urlPathForServingLocalPath('/foo/bar')
    authenticator = new PathAuthenticator()
    [errCode, localPath] = authenticator.localPathForUrlPath(urlPath)

    assert.equal errCode, 403
    assert.ok !localPath
