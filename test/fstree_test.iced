{ ok, deepEqual } = require 'assert'
FSTree = require '../lib/projects/tree'
fs     = require 'fs'
Path   = require 'path'
rimraf = require 'rimraf'
mkdirp = require 'mkdirp'

{ RelPathList } = require 'pathspec'


class TempDir
  constructor: ->
    @path = "/tmp/tmp-#{Date.now()}-#{Math.random().toString().substr(2)}"
    mkdirp.sync @path, 0o700
    process.on 'exit', @purge.bind(@)

  pathOf: (file) ->
    Path.join(@path, file)

  validate: (path) ->
    mkdirp.sync Path.dirname(path), 0o700

  put: (file, content) ->
    path = @pathOf(file)
    @validate path
    fs.writeFileSync path, content

  purge: ->
    return if @_purged
    @_purged = yes

    rimraf.sync @path


describe "FSTree", ->

  it "should read a tree with a single file", (done) ->
    tmpdir = new TempDir()
    tmpdir.put "foo.txt", "foo"

    tree = new FSTree(tmpdir.path)
    await tree.scan defer()

    deepEqual tree.errors, []
    deepEqual tree.getAllPaths(), ["foo.txt"]
    done()

  it "should read a largish tree", (done) ->
    tmpdir = new TempDir()
    tmpdir.put "foo.txt", "foo"
    tmpdir.put "bar.c", "foo"
    tmpdir.put "bar/boz.txt", "foo"
    tmpdir.put "bar/README.md", "foo"
    tmpdir.put "fubar/test.txt", "foo"

    tree = new FSTree(tmpdir.path)
    await tree.scan defer()

    deepEqual tree.errors, []
    deepEqual tree.getAllPaths(), ["bar.c", "bar/README.md", "bar/boz.txt", "foo.txt", "fubar/test.txt"]

    deepEqual tree.findMatchingPaths(RelPathList.parse(['*.txt'])), ["bar/boz.txt", "foo.txt", "fubar/test.txt"]

    done()
