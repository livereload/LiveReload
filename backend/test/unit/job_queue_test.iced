assert = require 'assert'
Job = require '../../lib/app/jobs'

class WooJob extends Job
  execute: (callback) ->
    @emit 'woo'
    callback(null)

class GooJob extends Job
  constructor: (@log, @realName, tags=[]) ->
    super(@realName.split('_')[0], tags)

  merge: (sibling) ->
    @log.push "#{@realName}.merge(#{sibling.realName})"

  execute: (callback) ->
    @log.push "#{@realName}.start"
    @emit 'goo'
    setTimeout =>
      @log.push "#{@realName}.finish"
      callback(null)
    , 5

class KooJob extends GooJob
  execute: (callback) ->
    @log.push @realName
    callback(null)


describe "JobQueue", ->

  it "should run a single submitted job", (done) ->
    queue = new Job.Queue(['default'])
    job = new WooJob "woo1"
    job.on 'woo', done
    queue.add job

  it "should run submitted jobs serially", (done) ->
    queue = new Job.Queue(['default'])
    log = []

    queue.add new GooJob log, 'goo1'
    queue.add new GooJob log, 'goo2'

    queue.once 'empty', ->
      assert.equal log.join(' '), "goo1.start goo1.finish goo2.start goo2.finish"
      done()

  it "should merge queued jobs with equal names", (done) ->
    queue = new Job.Queue(['default'])
    log = []

    queue.add new GooJob log, 'goo1_1'
    queue.add new GooJob log, 'goo2'
    queue.add new GooJob log, 'goo1_2'

    queue.once 'empty', ->
      assert.equal log.join(' '), "goo1_1.merge(goo1_2) goo1_1.start goo1_1.finish goo2.start goo2.finish"
      done()

  it "should not merge jobs if the existing job is already running", (done) ->
    queue = new Job.Queue(['default'])
    log = []

    queue.add new GooJob log, 'goo1_1'
    queue.add new GooJob log, 'goo2'
    queue.add new GooJob log, 'goo1_2'

    queue.once 'empty', ->
      assert.equal log.join(' '), "goo1_1.merge(goo1_2) goo1_1.start goo1_1.finish goo2.start goo2.finish"
      done()

  it "should run highest-priority jobs first", (done) ->
    queue = new Job.Queue(['high', 'default'])
    log = []

    queue.add new KooJob log, 'goo1'
    queue.add new KooJob log, 'goo2', ['high']
    queue.add new KooJob log, 'goo3'
    queue.add new KooJob log, 'goo4', ['high']

    queue.once 'empty', ->
      assert.equal log.join(' '), "goo2 goo4 goo1 goo3"
      done()

  it "should emit per-tag queue-empty events", (done) ->
    queue = new Job.Queue(['default'])
    log = []

    queue.add new KooJob log, 'goo1', ['foo']
    queue.add new KooJob log, 'goo2', ['bar']
    queue.add new KooJob log, 'goo3', ['foo']
    queue.add new KooJob log, 'goo4', ['bar']

    queue.on 'foo.empty', -> log.push 'foo.empty'
    queue.on 'bar.empty', -> log.push 'bar.empty'

    queue.once 'empty', ->
      assert.equal log.join(' '), "goo1 goo2 goo3 foo.empty goo4 bar.empty"
      done()
