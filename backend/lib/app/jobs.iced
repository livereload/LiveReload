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
    process.stderr.write "JobQueue enqueued: #{job}\n" if @verbose

    @schedule()

  schedule: ->
    return if @scheduled
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
    process.stderr.write "JobQueue empty\n" if @verbose
    @emit 'empty'

  executeJob: (job) ->
    @runningJob = job
    process.stderr.write "JobQueue running: #{job}\n" if @verbose

    # @emit 'running'
    # for tag in job.tags
    #   @emit "#{tag}.running"

    job.executeInQueue this, =>
      if @runningJob != job
        throw new Error "JobQueue internal error"
      @runningJob = null
      process.stderr.write "JobQueue finished: #{job}\n" if @verbose

      completedTags = []

      @jobCount -= 1
      for tag in job.tags
        if (--@tagToJobCount[tag]) is 0
          delete @tagToJobCount[tag]
          completedTags.push tag

      for tag in completedTags
        process.stderr.write "JobQueue empty for tag: #{tag}\n" if @verbose
        @emit "#{tag}.empty"

      @schedule()


Job.Queue = JobQueue
module.exports = Job
