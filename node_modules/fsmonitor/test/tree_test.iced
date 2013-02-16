{ ok, equal, deepEqual } = require 'assert'

fs           = require 'fs'
FSTree       = require '../lib/tree'
createTempFS = require('scopedfs').createTempFS.bind(null, 'fsmonitor-test-')


# HFS+ file mtime has 1s precision
DELAY = if process.platform is 'darwin' then 1000 else 100


describe "FSTree", ->

  it "should collect files and folders", (done) ->
    sfs = createTempFS()
    sfs.putSync 'foo.txt', "42"
    sfs.putSync 'zoo/boo.txt', "42"

    await
      tree = new FSTree(sfs.path)
      tree.once 'complete', defer()

    deepEqual tree.allFiles, ['foo.txt', 'zoo/boo.txt']
    deepEqual tree.allFolders, ['', 'zoo']
    done()


  describe "#findFilesBySuffix('foo/bar/boz.txt')", ->

    it "should return no matches when no boz.txt files exist", (done) ->
      sfs = createTempFS()
      sfs.putSync 'foo.txt', "42"
      sfs.putSync 'zoo/boo.txt', "42"

      await
        tree = new FSTree(sfs.path)
        tree.once 'complete', defer()

      await tree.findFilesBySuffix('foo/bar/boz.txt', {}, defer(err, result))
      deepEqual result.allMatches,  []
      deepEqual result.bestMatches, []
      deepEqual result.bestMatch,   null
      done()

    it "should return a single match when a single boz.txt file exists", (done) ->
      sfs = createTempFS()
      sfs.putSync 'foo.txt', "42"
      sfs.putSync 'zoo/boz.txt', "42"

      await
        tree = new FSTree(sfs.path)
        tree.once 'complete', defer()

      await tree.findFilesBySuffix('foo/bar/boz.txt', {}, defer(err, result))
      deepEqual result.allMatches,  [{ path: 'zoo/boz.txt', score: 1 }]
      deepEqual result.bestMatches, [{ path: 'zoo/boz.txt', score: 1 }]
      deepEqual result.bestMatch,    { path: 'zoo/boz.txt', score: 1 }
      done()

    it "should return two allMatches and one bestMatch when two inequal boz.txt files exist", (done) ->
      sfs = createTempFS()
      sfs.putSync 'foo.txt', "42"
      sfs.putSync 'zoo/boz.txt', "42"
      sfs.putSync 'bar/boz.txt', "42"

      await
        tree = new FSTree(sfs.path)
        tree.once 'complete', defer()

      await tree.findFilesBySuffix('foo/bar/boz.txt', {}, defer(err, result))
      deepEqual result.allMatches,  [{ path: 'bar/boz.txt', score: 2 }, { path: 'zoo/boz.txt', score: 1 }]
      deepEqual result.bestMatches, [{ path: 'bar/boz.txt', score: 2 }]
      deepEqual result.bestMatch,    { path: 'bar/boz.txt', score: 2 }
      done()

    it "should return two allMatches, two bestMatches and no bestMatch when two equal boz.txt files exist", (done) ->
      sfs = createTempFS()
      sfs.putSync 'foo.txt', "42"
      sfs.putSync 'zoo/bar/boz.txt', "42"
      sfs.putSync 'bar/boz.txt', "42"

      await
        tree = new FSTree(sfs.path)
        tree.once 'complete', defer()

      await tree.findFilesBySuffix('foo/bar/boz.txt', {}, defer(err, result))
      deepEqual result.allMatches,  [{ path: 'bar/boz.txt', score: 2 }, { path: 'zoo/bar/boz.txt', score: 2 }]
      deepEqual result.bestMatches, [{ path: 'bar/boz.txt', score: 2 }, { path: 'zoo/bar/boz.txt', score: 2 }]
      deepEqual result.bestMatch,   null
      done()

    it "should prefer matches from the bestSubtree", (done) ->
      sfs = createTempFS()
      sfs.putSync 'foo.txt', "42"
      sfs.putSync 'zoo/bar/boz.txt', "42"
      sfs.putSync 'bar/boz.txt', "42"

      await
        tree = new FSTree(sfs.path)
        tree.once 'complete', defer()

      await tree.findFilesBySuffix('foo/bar/boz.txt', { bestSubtree: 'zoo' }, defer(err, result))
      deepEqual result.allMatches,  [{ path: 'bar/boz.txt', score: 2 }, { path: 'zoo/bar/boz.txt', score: 2.5 }]
      deepEqual result.bestMatches, [{ path: 'zoo/bar/boz.txt', score: 2.5 }]
      deepEqual result.bestMatch,    { path: 'zoo/bar/boz.txt', score: 2.5 }
      done()


  describe '#update()', ->

    o = (initial, update, expectedChange, done) ->
      sfs = createTempFS()
      sfs.applySync(initial)

      await
        tree = new FSTree(sfs.path)
        tree.once 'complete', defer()

      await setTimeout defer(), DELAY

      sfs.applySync(update)
      await
        tree.update '', null, yes
        tree.once 'change', defer(change)

      equal change.toString(), ("#{line}\n" for line in expectedChange).join('')
      done()


    describe '(a single file change)', ->

      it "should note an added file in the root folder", (done) ->
        o {
          'foo.txt': '42'
        }, {
          'zoo.txt': '24'
        }, [
          '+zoo.txt'
        ], done

      it "should note an added file in a subfolder", (done) ->
        o {
          'zoo/foo.txt': '42'
        }, {
          'zoo/bar.txt': '24'
        }, [
          '+zoo/bar.txt'
        ], done

      it "should note a modified file in the root folder", (done) ->
        o {
          'foo.txt': '42'
        }, {
          'foo.txt': '24'
        }, [
          '!foo.txt'
        ], done

      it "should note a modified file in a subfolder", (done) ->
        o {
          'zoo/foo.txt': '42'
        }, {
          'zoo/foo.txt': '24'
        }, [
          '!zoo/foo.txt'
        ], done

      it "should note a removed file in the root folder", (done) ->
        o {
          'foo.txt': '42'
          'zoo.txt': '24'
        }, {
          'zoo.txt': null
        }, [
          '-zoo.txt'
        ], done

      it "should note a removed file in a subfolder", (done) ->
        o {
          'zoo/foo.txt': '42'
          'zoo/bar.txt': '24'
        }, {
          'zoo/bar.txt': null
        }, [
          '-zoo/bar.txt'
        ], done


    describe '(a single folder change)', ->

      it "should note an added subfolder", (done) ->
        o {
          'foo.txt': '42'
        }, {
          'zoo/': yes
        }, [
          '+zoo/'
        ], done

      it "should note a modified subfolder", (done) ->
        o {
          'zoo/foo.txt': '42'
        }, {
          'zoo': (path) -> fs.chmodSync(path, 0o777)
        }, [
          '!zoo/'
        ], done

      it "should note a removed subfolder", (done) ->
        o {
          'zoo/': yes
        }, {
          'zoo/': null
        }, [
          '-zoo/'
        ], done


    describe '(change affecting a non-empty subfolder)', ->

      it "should note added files in an added subfolder", (done) ->
        o {
          'foo.txt': '42'
        }, {
          'zoo/bar.txt': '24'
          'zoo/boz.txt': '11'
        }, [
          '+zoo/bar.txt'
          '+zoo/boz.txt'
          '+zoo/'
        ], done

      it "should note removed files in a removed subfolder", (done) ->
        o {
          'foo.txt': '42'
          'zoo/bar.txt': '24'
          'zoo/boz.txt': '11'
        }, {
          'zoo/': null
        }, [
          '-zoo/bar.txt'
          '-zoo/boz.txt'
          '-zoo/'
        ], done


    describe '(change affecting a subtree)', ->

      it "should note files and folders in an added subtree", (done) ->
        o {
        }, {
          'zoo/bar.txt': '24'
          'zoo/boz/foo.txt': '11'
        }, [
          '+zoo/bar.txt'
          '+zoo/boz/foo.txt'
          '+zoo/'
          '+zoo/boz/'
        ], done

      it "should note removed files and folders in a subtree", (done) ->
        o {
          'zoo/bar.txt': '24'
          'zoo/boz/foo.txt': '11'
        }, {
          'zoo/': null
        }, [
          '-zoo/bar.txt'
          '-zoo/boz/foo.txt'
          '-zoo/'
          '-zoo/boz/'
        ], done


    describe '(change affecting the root folder)', ->

      it "should note creation of the root folder", (done) ->
        o {
          '/': null
        }, {
          '/': yes
        }, [
          '+/'
        ], done

      it "should note deletion of the root folder", (done) ->
        o {
        }, {
          '/': null
        }, [
          '-/'
        ], done
