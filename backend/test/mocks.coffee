{ EventEmitter } = require 'events'

class MockHttpServer extends EventEmitter

  listen: (port, callback) ->
    callback()

class MockWebSocketServer extends EventEmitter

class MockWebSocket extends EventEmitter

  constructor: ->
    @messages = []

  send: (message) ->
    @messages.push message
    return

class MockFS
  constructor: (@path, @content) ->

  exists: (path, callback) ->
    callback(path is @path)

  readFile: (path, encoding=null, callback=null) ->
    unless callback?
      callback = encoding
      encoding = null

    if path isnt @path
      callback(new Error("File not found"))
    else
      content = switch
        when !encoding?          then new Buffer(content)
        when encoding is 'utf8'  then @content
        else                     throw new Error("Unsupported encoding: #{encoding}")
      callback(null, content)

module.exports = { MockHttpServer, MockWebSocketServer, MockWebSocket, MockFS }
