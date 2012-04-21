fs     = require 'fs'
assert = require 'assert'
wrap   = require '../wrap'

helper = require '../helper'

FSHive = require '../../lib/vfs/fshive'


describe "FSHive", ->
  it "should not do anything substantial in constructor", ->
    new FSHive('bar', '/foo/bar')

  it "should start monitoring on the first 'on' request, end monitoring on the last 'off' request", ->
    LR.client.allow 'monitoring.add'
    LR.client.allow 'monitoring.remove'

    hive = new FSHive('bar', '/foo/bar')
    hive.requestMonitoring 'xx', on
    assert.deepEqual LR.test.log, [['C.monitoring.add', { id: 'bar', path: '/foo/bar' }]]

    LR.test.clearLog()
    hive.requestMonitoring 'yy', on
    assert.deepEqual LR.test.log, []

    LR.test.clearLog()
    hive.requestMonitoring 'xx', off
    assert.deepEqual LR.test.log, []

    LR.test.clearLog()
    hive.requestMonitoring 'yy', off
    assert.deepEqual LR.test.log, [['C.monitoring.remove', { id: 'bar' }]]

  it "should emit 'change' when asked to process a change event", (done) ->
    hive = new FSHive('bar', '/foo/bar')
    _ok = no
    hive.on 'change', (changes) =>
      assert.deepEqual changes, ['foo/bar', 'boz']
      _ok = yes

    hive.handleFSChangeEvent { changes: ['foo/bar', 'boz'] }, (err) =>
      assert.ifError err
      assert.ok _ok
      done()

  it "should stop monitoring on dispose() if monitoring is on", ->
    LR.client.allow 'monitoring.add'
    LR.client.allow 'monitoring.remove'

    hive = new FSHive('bar', '/foo/bar')
    hive.requestMonitoring 'xx', on

    LR.test.clearLog()
    hive.dispose()
    assert.deepEqual LR.test.log, [['C.monitoring.remove', { id: 'bar' }]]


  it "should do nothing on dispose() if monitoring is off", ->
    hive = new FSHive('bar', '/foo/bar')
    hive.dispose()
    assert.deepEqual LR.test.log, []
