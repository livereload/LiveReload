{ ok, equal, strictEqual, deepEqual } = require 'assert'
R = require "../#{process.env.JSLIB or 'lib'}/reactive"


class FooModel extends R.Model
  schema:
    foo: {}


describe 'R.Model', ->

  it "should conform to EventEmitter protocol", (done) ->
    u = new R.Universe()
    m = u.create(FooModel)
    m.once 'foo', done
    m.emit 'foo'

  it "should be okay with creating multiple instances of a model", ->
    u = new R.Universe()
    m1 = u.create(FooModel)
    m2 = u.create(FooModel)

  describe "#initialize()", ->
    it "should be able to call #get() and #set()", ->
      class Ruby extends FooModel
        initialize: ->
          @set 'foo', 42
          equal @get('foo'), 42

      u = new R.Universe()
      m = u.create(Ruby)
      equal m.get('foo'), 42

  describe "#get()", ->

    it "should return a value set via #set()", ->
      u = new R.Universe()
      m = u.create(FooModel)
      m.set('foo', 42)
      equal m.get('foo'), 42

  describe "#has()", ->

    it "should return no for undefined attributes", ->
      u = new R.Universe()
      m = u.create(FooModel)
      equal m.has('foo'), no

    it "should return no for attributes set to undefined", ->
      u = new R.Universe()
      m = u.create(FooModel)
      m.set('foo', undefined)
      equal m.has('foo'), no

    it "should return no for attributes set to null", ->
      u = new R.Universe()
      m = u.create(FooModel)
      m.set('foo', null)
      equal m.has('foo'), no

    it "should return yes for attributes set to anything else", ->
      u = new R.Universe()
      m = u.create(FooModel)
      m.set('foo', '')
      equal m.has('foo'), yes

  describe "#set()", ->

    it "should emit a change event on R.Universe", (done) ->
      u = new R.Universe()
      m = u.create(FooModel)

      await
        u.once 'change', defer(model, attr)
        m.set 'foo', 42
      equal model, m
      equal attr, 'foo'

      u.destroy()
      done()

    it "should emit the change event asynchronously", (done) ->
      u = new R.Universe()
      m = u.create(FooModel)

      u.once 'change', ->
        ok afterSet
        done()

      m.set 'foo', 42
      afterSet = yes

    it "should emit the change event once for any number of consecutive changes", (done) ->
      u = new R.Universe()
      m = u.create(FooModel)

      count = 0
      u.on 'change', ->
        ++count
        equal m.get('foo'), 44
      u.then ->
        equal count, 1
        equal m.get('foo'), 44
        done()

      m.set 'foo', 42
      m.set 'foo', 43
      m.set 'foo', 44


  describe "accessors defined by a schema", ->

    it "should return a previously set value", ->
      u = new R.Universe()
      m = u.create(FooModel)
      m.foo = 42
      equal m.foo, 42

    it "should emit a change event on write", (done) ->
      u = new R.Universe()
      m = u.create(FooModel)

      await
        u.once 'change', defer(model, attr)
        m.foo = 42
      equal model, m
      equal attr, 'foo'

      u.destroy()
      done()


  describe "with default values", ->

    it "should initialize a property with the specified default value", ->
      class BarModel extends R.Model
        schema:
          foo: { type: 'int', default: 42 }
      u = new R.Universe()
      m = u.create(BarModel)
      strictEqual m.foo, 42

    it "should initialize a property with its type's default value when no explicit default is specified", ->
      class BarModel extends R.Model
        schema:
          foo: { type: 'int' }
      u = new R.Universe()
      m = u.create(BarModel)
      strictEqual m.foo, 0

    it "should initialize a property with null when neither type nor explicit default is specified", ->
      class BarModel extends R.Model
        schema:
          foo: {}
      u = new R.Universe()
      m = u.create(BarModel)
      strictEqual m.foo, null


  describe "with a computed property", ->

    class BarModel extends R.Model
      schema:
        foo: { type: 'int', default: 42 }
        bar: { type: 'int', computed: yes }
      'compute bar': ->
        @foo * 101

    it "should initially set computed properties to their default values", ->
      u = new R.Universe()
      m = u.create(BarModel)
      equal m.bar, 0

    it "should eventually compute the value of a computed property", ->
      u = new R.Universe()
      m = u.create(BarModel)
      await u.then defer()
      equal m.bar, 4242

    it "should recompute the value of a computed property when its dependencies change", ->
      u = new R.Universe()
      m = u.create(BarModel)
      await u.then defer()

      m.foo = 24
      await u.then defer()
      equal m.bar, 2424

    it "should recompute the value of a computed property when its outside dependencies change", ->
      class BozModel extends R.Model
        schema:
          bar: { type: 'int', computed: yes }
        'compute bar': ->
          @foo.foo * 101

      u = new R.Universe()
      m = u.create(BozModel)
      m.foo = u.create(FooModel)
      m.foo.foo = 42
      await u.then defer()

      m.foo.foo = 24
      await u.then defer()
      equal m.bar, 2424

    it "should resubscribe when dependencies change", ->
      u = new R.Universe()

      foo1 = u.create(FooModel)
      foo1.foo = 11

      foo2 = u.create(FooModel)
      foo2.foo = 22

      class BozModel extends R.Model
        schema:
          ref: { type: FooModel }
          bar: { type: 'int', computed: yes }
        'compute bar': ->
          @ref.foo * 101

      m = u.create(BozModel)
      m.ref = foo1

      await u.then defer()
      equal m.bar, 1111
      ok foo1._subscribers.length > 0
      ok foo2._subscribers.length == 0

      m.ref = foo2
      await u.then defer()
      equal m.bar, 2222
      ok foo1._subscribers.length == 0
      ok foo2._subscribers.length > 0

    it "should turn methods named 'automatically something' into blocks", ->
      values = []

      class BozModel extends R.Model
        schema:
          foo: { type: 'int' }
        'automatically do something': ->
          values.push @foo

      u = new R.Universe()
      m = u.create(BozModel)

      await u.then defer()
      deepEqual values, [0]

      m.foo = 42
      await u.then defer()
      deepEqual values, [0, 42]

    it "should update a cascade of dependent values", ->
      class BozModel extends R.Model
        schema:
          foo: { type: 'int' }
          bar: { type: 'int', computed: yes }
          boz: { type: 'int', computed: yes }
        'compute bar': ->
          @foo * 101
        'compute boz': ->
          @bar + 1

      u = new R.Universe()
      m = u.create(BozModel)

      m.foo = 42
      await u.then defer()
      await process.nextTick defer()
      equal m.bar, 4242
      equal m.boz, 4243

      m.foo = 24
      await u.then defer()
      await process.nextTick defer()
      equal m.bar, 2424
      equal m.boz, 2425

    it "should prevent cascaded updates when manually-set values don't actually change", ->
      log = []

      class BozModel extends R.Model
        schema:
          foo: { type: 'int' }
          bar: { type: 'int', computed: yes }
          boz: { type: 'int', computed: yes }
        'compute bar': ->
          log.push 'bar'
          @foo % 5
        'compute boz': ->
          log.push 'boz'
          @bar * 10

      u = new R.Universe()
      m = u.create(BozModel)

      m.foo = 42
      await u.then defer()
      await process.nextTick defer()
      equal m.bar, 2
      equal m.boz, 20
      deepEqual log, ['bar', 'boz']

      m.foo = 42
      await u.then defer()
      await process.nextTick defer()
      equal m.bar, 2
      equal m.boz, 20
      deepEqual log, ['bar', 'boz']

    it "should prevent cascaded updates when computed values don't actually change", ->
      log = []

      class BozModel extends R.Model
        schema:
          foo: { type: 'int' }
          bar: { type: 'int', computed: yes }
          boz: { type: 'int', computed: yes }
        'compute bar': ->
          log.push 'bar'
          @foo % 5
        'compute boz': ->
          log.push 'boz'
          @bar * 10

      u = new R.Universe()
      m = u.create(BozModel)

      m.foo = 42
      await u.then defer()
      await process.nextTick defer()
      equal m.bar, 2
      equal m.boz, 20
      deepEqual log, ['bar', 'boz']

      m.foo = 27
      await u.then defer()
      await process.nextTick defer()
      equal m.bar, 2
      equal m.boz, 20
      deepEqual log, ['bar', 'boz', 'bar']

  describe "with a block", ->

    it "should reinvoke the block when dependent values change", ->
      log = []
      class BozModel extends R.Model
        schema:
          foo: { type: 'int' }

      u = new R.Universe()
      m = u.create(BozModel)

      m.foo = 42
      m.pleasedo "smt", -> log.push m.foo

      await u.then defer()
      await process.nextTick defer()
      deepEqual log, [42]

      m.foo = 24
      await u.then defer()
      await process.nextTick defer()
      deepEqual log, [42, 24]
