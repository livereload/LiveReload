{ ok, equal } = require 'assert'
R             = require '../lib/reactive'


describe 'R.Model', ->

  describe "#get()", ->

    it "should return a value set via #set()", ->
      m = new R.Model()
      m.set('foo', 42)
      equal m.get('foo'), 42

  describe "#has()", ->

    it "should return no for undefined attributes", ->
      m = new R.Model()
      equal m.has('foo'), no

    it "should return no for attributes set to undefined", ->
      m = new R.Model()
      m.set('foo', undefined)
      equal m.has('foo'), no

    it "should return no for attributes set to null", ->
      m = new R.Model()
      m.set('foo', null)
      equal m.has('foo'), no

    it "should return yes for attributes set to anything else", ->
      m = new R.Model()
      m.set('foo', '')
      equal m.has('foo'), yes
