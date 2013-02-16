{ ok, equal } = require 'assert'

NodeWatcher = require '../lib/watchers/node'
createTempFS = require('scopedfs').createTempFS.bind(null, 'fsmonitor-test-')

DELAY = 100


describe "NodeWatcher", ->


  it "shouldn't emit 'change' before any modifications are made", (done) ->
    sfs = createTempFS()
    sfs.putSync 'foo.txt', "42"
    await setTimeout defer(), DELAY

    watcher = new NodeWatcher(sfs.path)
    watcher.addFolder ''

    watcher.once 'change', -> ok no, "'change' was emitted"
    await setTimeout defer(), 500

    watcher.close()
    done()


  it "should emit 'change' on modification of the root folder's file", (done) ->
    sfs = createTempFS()
    sfs.putSync 'foo.txt', "42"
    await setTimeout defer(), DELAY

    watcher = new NodeWatcher(sfs.path)
    watcher.addFolder ''

    await
      watcher.once 'change', defer(folder, filename, recursive)
      sfs.putSync 'foo.txt', "24"

    equal folder, ''

    watcher.close()
    done()


  it "should emit 'change' on modification of a subfolder's file", (done) ->
    sfs = createTempFS()
    sfs.putSync 'aa/bb/foo.txt', "42"
    await setTimeout defer(), DELAY

    watcher = new NodeWatcher(sfs.path)
    watcher.addFolder ''
    watcher.addFolder 'aa'
    watcher.addFolder 'aa/bb'

    await
      watcher.once 'change', defer(folder, filename, recursive)
      sfs.putSync 'aa/bb/foo.txt', "24"

    equal folder, 'aa/bb'

    watcher.close()
    done()
