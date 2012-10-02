{ ok, deepEqual } = require 'assert'
Graph = require '../lib/projects/graph'

describe "Graph", ->

  createKindaFullGraph = ->
    g = new Graph()
    g.updateOutgoing 'a', ['b', 'c', 'd']
    g.updateOutgoing 'b', ['c', 'd']
    g.updateOutgoing 'c', ['d']
    return g

  it "should be perfectly empty when created", ->
    g = new Graph()
    deepEqual g.contents(), []

  describe '#updateOutgoing()', ->

    it "should handle the initial update", ->
      g = new Graph()
      g.updateOutgoing 'a', ['b', 'c']
      deepEqual g.contents(), ["a -> b, c", "b <- a", "c <- a"]

    it "should handle removal of an edge", ->
      g = new Graph()
      g.updateOutgoing 'a', ['b', 'c']
      g.updateOutgoing 'a', ['b']
      deepEqual g.contents(), ["a -> b", "b <- a"]

    it "should handle addition of an edge", ->
      g = new Graph()
      g.updateOutgoing 'a', ['b', 'c']
      g.updateOutgoing 'a', ['b', 'c', 'd']
      deepEqual g.contents(), ["a -> b, c, d", "b <- a", "c <- a", "d <- a"]

    it "should handle a kinda-full graph", ->
      g = createKindaFullGraph()
      deepEqual g.contents(), ["a -> b, c, d", "b -> c, d", "c -> d", "b <- a", "c <- a, b", "d <- a, b, c"]

  describe '#remove()', ->

    it "should handle removal of a node from a kinda-full graph", ->
      g = createKindaFullGraph()
      g.remove 'c'
      deepEqual g.contents(), ["a -> b, d", "b -> d", "b <- a", "d <- a, b"]

  describe '#findSources()', ->

    it "should find root nodes in a simple two-vertex graph", ->
      g = new Graph()
      g.updateOutgoing 'a', ['b']
      deepEqual g.findSources('a'), ['a']
      deepEqual g.findSources('b'), ['a']

    it "should find root nodes in a kinda-full graph", ->
      g = new Graph()
      g = createKindaFullGraph()
      deepEqual g.findSources('a'), ['a']
      deepEqual g.findSources('b'), ['a']
      deepEqual g.findSources('c'), ['a']
      deepEqual g.findSources('d'), ['a']

    it "should find multiple root nodes in a kinda-full graph with an additional vertex", ->
      g = new Graph()
      g = createKindaFullGraph()
      g.updateOutgoing 'x', ['b', 'c']
      deepEqual g.findSources('a'), ['a']
      deepEqual g.findSources('b'), ['a', 'x']
      deepEqual g.findSources('c'), ['a', 'x']
      deepEqual g.findSources('d'), ['a', 'x']
