{ createApiTree } = require '../lib/apitree'
assert = require 'assert'

find = (tree, path) ->
  for component in path.split('/') when component isnt '.'
    tree = tree[component]
    throw new Error("Path not found") if !tree
  tree

findDir = (tree, path) ->
  item = find(tree, path)
  return item unless item.length?

createOptions = (tree, options={}) ->
  options.readdirSync = (path) ->
    if item = findDir(tree, path)
      return Object.keys(item).sort()
    else
      throw new Error("Not a directory")

  options.isDirectory = (path) -> !!findDir(tree, path)

  options.loadItem = (path) ->
    result = {}
    for name, index in find(tree, path)
      result[name] = "i#{index}"
    result

  return options

T = (tree, options={}) -> createApiTree('.', createOptions(tree, options))

describe "API tree", ->

  describe "when given an empty folder", ->
    tree = T {}

    it "should return an empty tree", ->
      assert.deepEqual tree, {}

  describe "when given a folder with a single file", ->
    tree = T {'foo.js': ['bar', 'boz']}

    it "should put the file node under the tree root", ->
      assert.equal Object.keys(tree).length, 1

    it "should strip the extension when naming the tree node", ->
      assert.deepEqual Object.keys(tree), ['foo']

    it "should put the file's contents under its node", ->
      assert.deepEqual Object.keys(tree.foo).sort(), ['bar', 'boz']

  describe "when given a file and a subfolder", ->
    tree = T {'foo.js': ['bar', 'boz'], fold: {'fil.js': ['fubar']}}

    it "should put the file and subfolder nodes together under the tree root", ->
      assert.deepEqual Object.keys(tree).sort(), ['fold', 'foo']

  describe "when given a file and a subfolder which have the same name after stripping extensions", ->
    tree = T {'foo.js': ['bar', 'boz'], foo: {'fil.js': ['fubar']}}

    it "should merge the file and the subfolder into a single node under the tree root", ->
      assert.deepEqual Object.keys(tree), ['foo']
      assert.deepEqual Object.keys(tree.foo).sort(), ['bar', 'boz', 'fil']

  describe "when given a folder hierarchy with nested subfolders", ->
    tree = T {foo: {bar: {'boz.js': ['fubar']}}}

    it "should reproduce the folder hierarachy inside the API tree", ->
      assert.deepEqual Object.keys(tree), ['foo']
      assert.deepEqual Object.keys(tree.foo), ['bar']
      assert.deepEqual Object.keys(tree.foo.bar), ['boz']
      assert.deepEqual Object.keys(tree.foo.bar.boz), ['fubar']

  describe "loadItem callback", ->

    it "should be used to obtain file contents", ->
      tree = T {'foo.js': ['bar', 'boz']}
      assert.equal tree.foo.bar, 'i0'
      assert.equal tree.foo.boz, 'i1'

  describe "nameToKey callback", ->

    args = null
    nameToKey = (name) -> args = arguments; "A#{name.split('.')[0]}Z"

    it "should accept file name as the only argument", ->
      tree = T {'foo.js': ['bar', 'boz']}, {nameToKey}
      assert.equal args.length, 1
      assert.equal args[0], 'foo.js'

    it "should be used to translate file names into tree keys", ->
      tree = T {'foo.js': ['bar', 'boz']}, {nameToKey}
      assert.deepEqual Object.keys(tree), ['AfooZ']

    it "should be used to translate subfolder names into tree keys", ->
      tree = T {foo: {'bar.js': ['bar', 'boz']}}, {nameToKey}
      assert.deepEqual Object.keys(tree), ['AfooZ']

    it "should not be used to modify keys returned by loadItem", ->
      tree = T {'foo.js': ['bar', 'boz']}, {nameToKey}
      assert.deepEqual Object.keys(tree.AfooZ).sort(), ['bar', 'boz']

  describe "default nameToKey callback", ->

    it "should strip file extension", ->
      tree = T {'foo.js': ['bar']}
      assert.deepEqual Object.keys(tree), ['foo']

    it "should replace any non-identifier characters with underscores", ->
      tree = T {'foo-bar.js': ['bar']}
      assert.deepEqual Object.keys(tree), ['foo_bar']

    it "should replace runs of multiple non-identifier characters with a single underscore", ->
      tree = T {'foo!!bar.js': ['bar']}
      assert.deepEqual Object.keys(tree), ['foo_bar']

  describe "filter callback", ->

    args = null
    filter = (name, names) -> args = `arguments`; name is 'foo.js'

    it "should accept file name as the first argument", ->
      tree = T {'foo.js': ['fu']}, {filter}
      assert.equal args[0], 'foo.js'

    it "should accept the list of all file names in the same folder as the second argument", ->
      tree = T {'foo.js': ['fu'], 'bar.js': ['ba']}, {filter}
      assert.deepEqual args[1].sort(), ['bar.js', 'foo.js']
      assert.equal args.length, 2

    it "should be used to choose which files to process", ->
      tree = T {'foo.js': ['fu'], 'bar.js': ['ba']}, {filter}
      assert.deepEqual Object.keys(tree), ['foo']

    it "should have no effect on which folders are processed", ->
      tree = T {'foo.js': ['fu'], 'fold': {'foo.js': ['uf'], 'bar.js': ['ba']}}, {filter}
      assert.deepEqual Object.keys(tree).sort(), ['fold', 'foo']
      assert.deepEqual Object.keys(tree.fold), ['foo']

  describe "default filter callback", ->

    require.extensions['.tjs'] = require.extensions['.js']

    tree = T {
      'foo.js'     : ['xx']
      'bar.js'     : ['yy']
      'foo.txt'    : ['zz']
      'Rakefile'   : ['rr']
      'boz.coffee' : ['cc']
      'both.js'    : ['bb']
      'both.coffee': ['BB']
      'alien.tjs'  : ['aa']
      'alienC.js'  : ['ll']
      'alienC.tjs' : ['LL']
      'data.json'  : ['dd']
    }, {nameToKey: (name) -> name}

    it "should include .js files", ->
      assert.ok 'foo.js' of tree
      assert.ok 'bar.js' of tree

    it "should include .coffee files that don't have corresponding .js files", ->
      assert.ok 'boz.coffee' of tree

    it "should include registered extension files that don't have corresponding .js files", ->
      assert.ok 'alien.tjs' of tree

    it "should only include .js file when both .js and .coffee files exist", ->
      assert.ok 'both.js' of tree
      assert.ok !('both.coffee' of tree)

    it "should only include .js file when both registered extension file and .js files exist", ->
      assert.ok 'alienC.js' of tree
      assert.ok !('alienC.tjs' of tree)

    it "should not include any other files", ->
      assert.ok !('Rakefile' of tree)
      assert.ok !('foo.txt' of tree)
      assert.ok !('data.json' of tree)
