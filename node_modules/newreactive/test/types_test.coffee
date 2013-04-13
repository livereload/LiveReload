{ ok, equal, deepEqual, throws } = require 'assert'
types = require "../#{process.env.JSLIB or 'lib'}/types"

describe 'types', ->

  describe '.resolve', ->

    it "should resolve String into a string type", ->
      equal types.resolve(String).toString(), 'string'

    it "should resolve 'int' into an integer type", ->
      equal types.resolve('int').toString(), 'int'

    it "should resolve Array into array(any)", ->
      equal types.resolve(Array).toString(), "{ array: any }"

    it "should resolve { array: 'int' } into array(int)", ->
      equal types.resolve({ array: 'int' }).toString(), "{ array: int }"

    it "should resolve { object: Foo } into object(Foo)", ->
      class Foo
      equal types.resolve({ object: Foo }).toString(), "{ object: Foo }"

  describe 'array(int).coerce', ->

    it "should turn [1, '2'] into [1, 2]", ->
      equal JSON.stringify(types.coerce([1, '2'], { array: 'int' })), JSON.stringify([1, 2])

  describe 'object(Foo)', ->

    it "should complain about mismatched object types when given an instance of unrelated class", ->
      class Foo
      class Bar
      throws (-> types.coerce(new Bar(), Foo)), /Invalid Bar value/
