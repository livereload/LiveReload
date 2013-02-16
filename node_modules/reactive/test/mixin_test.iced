{ ok, equal, strictEqual, deepEqual } = require 'assert'
R = require "../#{process.env.JSLIB or 'lib'}/reactive"


describe 'R.Model mixins', ->

  it "should handle mixins", (done) ->
    class FooModel extends R.Model
      schema:
        foo: { type: 'int' }

      sum: (a, b) ->
        a + b

    class BarMixin
      schema:
        bar: { type: 'int' }
        boz: { type: 'int', computed: yes }

      'compute boz': ->
        console.error "compute boz, this = %j", this.constructor.name
        @sum(@foo, @bar)


    u = new R.Universe()
    u.mixin(FooModel, BarMixin)

    m = u.create(FooModel, foo: 42, bar: 100)
    equal m.foo, 42
    equal m.sum(1, 2), 3
    equal m.bar, 100

    await u.then defer()
    await process.nextTick defer()

    equal m.boz, 142
    done()
