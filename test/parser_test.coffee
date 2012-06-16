assert = require 'assert'

LRProtocolParser = require '../lib/parser'


createParser = (role, protocols) ->
  parser = new LRProtocolParser(role, protocols)
  parser.on 'command', (c) ->
    parser.lastCommand = c
  parser.on 'error', (e) ->
    parser.lastErrorCode = e.code || 'UNKNOWN'
    parser.lastErrorMessage = e.message || ''
  parser.lastCommand = parser.lastErrorCode = null
  return parser


DUMMY_1 =
  version: 1
  url: "http://example.com/dummy-lr-protocol/1"
  server_commands:
    'omg':
      'foo': []
  client_commands:
    'wtf':
      'bar': ['string']
    'wtf2':
      'bar': ['required', 'string']
DUMMY_2 =
  version: 2
  url: "http://example.com/dummy-lr-protocol/2"
  server_commands:
    'omg':
      'foo': []
  client_commands:
    'wtf':
      'bar': ['string']
    'wtf4': {}
XDUMMY_1 =
  version: 1
  url: "http://example.com/extra-dummy-lr-protocol/1"
  server_commands: {}
  client_commands:
    'wtf':
      'boz': []
    'wtf3': {}


describe "LRProtocolParser", ->

  it "should reject bogus data", ->
    parser = createParser('server', {})
    parser.received "qwerty"
    assert.equal parser.lastErrorCode, LRProtocolParser.ERR_DATA
    assert.equal parser.lastCommand, null

  it "should reject JSON data that is not a message", ->
    parser = createParser('server', {})
    parser.received "[1,2,3]"
    assert.equal parser.lastErrorCode, LRProtocolParser.ERR_DATA
    assert.equal parser.lastCommand, null

  it "should reject commands before receiving HELLO", ->
    parser = createParser('server', { dummy: [DUMMY_1] })
    parser.received JSON.stringify({ command: 'info' })
    assert.equal parser.lastErrorCode, 'CMD'

  it "should reject a handshake with no supported protocols", ->
    parser = createParser('server', { dummy: [DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: ['whatever'] })
    assert.equal parser.lastErrorCode, LRProtocolParser.ERR_NOPROTO
    assert.equal parser.lastCommand, null

  it "should accept a handshake with a known protocol", ->
    parser = createParser('server', { dummy: [DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url] })
    assert.deepEqual parser.negotiatedProtocols, { dummy: 1 }

  it "should accept a handshake with the first version of a protocol with two known versions", ->
    parser = createParser('server', { dummy: [DUMMY_2, DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url] })
    assert.deepEqual parser.negotiatedProtocols, { dummy: 1 }

  it "should accept a handshake with the first version of a protocol with two known versions", ->
    parser = createParser('server', { dummy: [DUMMY_2, DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_2.url] })
    assert.deepEqual parser.negotiatedProtocols, { dummy: 2 }

  it "should accept a handshake with both versions of a protocol with two known versions", ->
    parser = createParser('server', { dummy: [DUMMY_2, DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url, DUMMY_2.url] })
    assert.deepEqual parser.negotiatedProtocols, { dummy: 2 }

  it "should accept a handshake with two known protocols", ->
    parser = createParser('server', { dummy: [DUMMY_1], xdummy: [XDUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url, XDUMMY_1.url] })
    assert.deepEqual parser.negotiatedProtocols, { dummy: 1, xdummy: 1 }

  it "should allow any keys in the HELLO message", ->
    parser = createParser('server', { dummy: [DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url], foo: 'bar' })
    assert.equal parser.lastErrorCode, null
    assert.deepEqual parser.negotiatedProtocols, { dummy: 1 }

  it "should emit 'connected' after a successful negotiation", ->
    parser = createParser('server', { dummy: [DUMMY_1] })

    connected = no
    parser.once 'connected', -> connected = yes
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url] })
    assert.equal connected, yes

  it "should parse valid commands", ->
    parser = createParser('server', { dummy: [DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url] })

    parser.received JSON.stringify({ command: 'wtf' })
    assert.equal parser.lastErrorCode, null
    assert.deepEqual parser.lastCommand, { command: 'wtf' }

  it "should permit valid attributes", ->
    parser = createParser('server', { dummy: [DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url] })

    parser.received JSON.stringify({ command: 'wtf', bar: 'qwerty' })

  it "should emit 'error' on attributes whose value does not pass the specified validators", ->
    parser = createParser('server', { dummy: [DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url] })

    parser.received JSON.stringify({ command: 'wtf', bar: 42 })
    assert.equal parser.lastErrorCode, 'ATTR'

  it "should emit 'error' on invalid attributes", ->
    parser = createParser('server', { dummy: [DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url] })

    parser.received JSON.stringify({ command: 'wtf', boz: 'qwerty' })
    assert.equal parser.lastErrorCode, 'ATTR'

  it "should emit 'error' on attributes whose values do not pass the specified validators", ->
    parser = createParser('server', { dummy: [DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url] })

    parser.received JSON.stringify({ command: 'wtf', bar: 42 })
    assert.equal parser.lastErrorCode, 'ATTR'

  it "should emit 'error' on missing required attributes", ->
    parser = createParser('server', { dummy: [DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url] })

    parser.received JSON.stringify({ command: 'wtf2' })
    assert.equal parser.lastErrorCode, 'ATTR'

  it "should permit valid attributes specified in a second protocol", ->
    parser = createParser('server', { dummy: [DUMMY_1], xdummy: [XDUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url, XDUMMY_1.url] })

    parser.received JSON.stringify({ command: 'wtf', bar: 'qwerty', boz: 42 })
    assert.equal parser.lastErrorCode, null

  it "should emit 'error' on attributes specified in an inactive protocol", ->
    parser = createParser('server', { dummy: [DUMMY_1], xdummy: [XDUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url] })

    parser.received JSON.stringify({ command: 'wtf', bar: 'qwerty', boz: 42 })
    assert.equal parser.lastErrorCode, 'ATTR'

  it "should permit a valid outgoing command", ->
    parser = createParser('server', { dummy: [DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url] })
    parser.sending { command: 'omg' }

  it "should throw an error on invalid outgoing command", ->
    parser = createParser('server', { dummy: [DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url] })
    assert.throws ->
      parser.sending { command: 'wtf' }
    , /Invalid command/


  it "should throw an error on invalid attribute in an outgoing command", ->
    parser = createParser('server', { dummy: [DUMMY_1] })
    parser.received JSON.stringify({ command: 'hello', protocols: [DUMMY_1.url] })
    assert.throws ->
      parser.sending { command: 'omg', bar: 42 }
    , /Invalid attribute/

