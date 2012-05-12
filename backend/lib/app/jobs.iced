log = require('dreamlog')('jobqueue')
{ EventEmitter } = require 'events'

class Job extends EventEmitter

  constructor: (instanceName, @tags=[]) ->
    if Object.isArray instanceName
      instanceName = ('' + component for component in instanceName).join('-')
    @name = @constructor.name + (instanceName && "-#{instanceName}" || '')
    @tags.push @constructor.name
    @complete = no
    @error = null

  # these conditions are evaluated before queueing the job and once again before running it
  superfluous: ->
    no

  merge: (sibling) ->
    throw new Error "#{this} does not support de-duplication"

  executeInQueue: (queue, callback) ->
    @executeOrSkip (err) =>
      if @complete
        throw new Error("#{this}.execute called its callback twice")
      @complete = yes

      if err
        @error = err

      @emit 'complete', this
      callback()

  executeOrSkip: (callback) ->
    if @superfluous()
      callback(null)
    else
      @execute(callback)

  execute: (callback) ->
    throw new Error "#{this}.execute not implemented"

  toString: ->
    "#{@name}(#{@tags.join(',')})"


class JobQueue extends EventEmitter

  constructor: (@priorities) ->
    @nameToJob = {}

    @priorityToJobs = {}
    for priority in @priorities
      @priorityToJobs[priority] = []

    @tagToJobCount = {}
    @jobCount = 0
    @runningJob = null
    @scheduled = no
    @verbose = no

  add: (job) ->
    job.priority = @priorities.intersect(job.tags.concat(['default'])).first() or throw new Error "No priority specified for #{job}"

    return if job.superfluous()

    if existingJob = @nameToJob[job.name]
      existingJob.merge(job)
      return

    @nameToJob[job.name] = job
    @priorityToJobs[job.priority].push job

    @jobCount += 1
    for tag in job.tags
      @tagToJobCount[tag] = (@tagToJobCount[tag] || 0) + 1
    log.debug "JobQueue enqueued: #{job}"

    @schedule()

  schedule: ->
    return if @scheduled or @runningJob
    @scheduled = yes

    process.nextTick =>
      @scheduled = no
      @executeNextJob()

  executeNextJob: ->
    for priority in @priorities
      if job = @priorityToJobs[priority].shift()
        delete @nameToJob[job.name]
        @executeJob job
        return
    log.info "JobQueue empty"
    @emit 'empty'

  executeJob: (job) ->
    @runningJob = job
    log.info "JobQueue running: #{job}"

    @emit 'running'
    # for tag in job.tags
    #   @emit "#{tag}.running"

    job.executeInQueue this, =>
      if @runningJob != job
        throw new Error "JobQueue internal error: @runningJob == #{@runningJob}, but the finished job is #{job}"
      @runningJob = null
      log.info "JobQueue finished: #{job}"

      completedTags = []

      @jobCount -= 1
      for tag in job.tags
        if (--@tagToJobCount[tag]) is 0
          delete @tagToJobCount[tag]
          completedTags.push tag

      for tag in completedTags
        log.debug "JobQueue empty for tag: #{tag}"
        @emit "#{tag}.empty"

      @schedule()


Job.Queue = JobQueue
module.exports = Job
