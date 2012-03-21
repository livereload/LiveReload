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

module.exports = { MockHttpServer, MockWebSocketServer, MockWebSocket }
