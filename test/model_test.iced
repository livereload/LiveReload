assert = require 'assert'
R      = require '../lib/reactive'


describe 'R.Model', ->

  describe "#get()", ->

    it "should return a value set via #set()", ->
      model = new R.Model()
      model.set('foo', 42)
      assert.equal model.get('foo'), 42

  describe "#has()", ->

    it "should return no for undefined attributes", ->
      model = new R.Model()
      assert.equal model.has('foo'), no

    it "should return no for attributes set to undefined", ->
      model = new R.Model()
      model.set('foo', undefined)
      assert.equal model.has('foo'), no

    it "should return no for attributes set to null", ->
      model = new R.Model()
      model.set('foo', null)
      assert.equal model.has('foo'), no

    it "should return yes for attributes set to anything else", ->
      model = new R.Model()
      model.set('foo', '')
      assert.equal model.has('foo'), yes
