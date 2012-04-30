assert = require 'assert'
wrap   = require '../wrap'

R = require '../../lib/reactive'
R.autoflush = no

describe "Reactive", ->
  it "should handle non-reactive reads and writes", ->
    foo = new R.Entity()
    foo.__defprop 'bar', 42
    assert.equal foo.bar, 42

    foo.bar = 24
    assert.equal foo.bar, 24

  it "should re-invoke consumer functions when a reactive var is updated", ->
    foo = new R.Entity()
    foo.__defprop 'bar', 42

    values = []
    R.run ->
      values.push foo.bar

    assert.deepEqual values, [42]

    foo.bar = 24
    assert.deepEqual values, [42]
    R.flush()
    assert.deepEqual values, [42, 24]

  it "should ARR re-invoke consumer functions when a reactive var is updated", ->
    foo = new R.Entity()
    foo.__defprop 'bar', [42]

    values = []
    R.run ->
      values.push foo.bar.toJSON()

    assert.deepEqual values, [[42]]

    foo.bar.push 24
    assert.deepEqual values, [[42]]
    R.flush()
    assert.deepEqual values, [[42], [42,24]]
