{ ok, equal, deepEqual } = require 'assert'

fs           = require 'fs'
FSMonitor    = require '../lib/monitor'
createTempFS = require('scopedfs').createTempFS.bind(null, 'fsmonitor-test-')


# HFS+ file mtime has 1s precision
DELAY = if process.platform is 'darwin' then 1000 else 100


describe "FSMonitor", ->

  it "should provide an initial tree", (done) ->
    sfs = createTempFS()
    sfs.putSync 'foo.txt', "42"
    sfs.putSync 'zoo/boo.txt', "42"

    await
      monitor = new FSMonitor(sfs.path)
      monitor.once 'complete', defer()

    deepEqual monitor.tree.allFiles, ['foo.txt', 'zoo/boo.txt']
    monitor.close()
    done()


  o = (initial, update, expectedChange, done) ->
    sfs = createTempFS()
    sfs.applySync(initial)

    await
      monitor = new FSMonitor(sfs.path)
      monitor.once 'complete', defer()

    await setTimeout defer(), DELAY

    await
      monitor.once 'change', defer(change)
      sfs.applySync(update)

    equal change.toString(), ("#{line}\n" for line in expectedChange).join('')
    monitor.close()
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

    it "should note creation of the root folder (EXPECTED TO FAIL)", (done) ->
      o {
        '/': null
      }, {
        '/': yes
      }, [
        '+/'
      ], done

    it "should note deletion of the root folder (EXPECTED TO FAIL)", (done) ->
      o {
      }, {
        '/': null
      }, [
        '-/'
      ], done
