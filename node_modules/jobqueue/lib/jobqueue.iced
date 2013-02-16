# Job queue runs a set of jobs serially, providing additional request merging and introspection
# capabilities.

# Imports
{ EventEmitter } = require 'events'
{ inspect }      = require 'util'
debug            = require('debug')('jobqueue')

# ### JobQueue public API

# JobQueue is the class returned when you `require('jobqueue')`.
module.exports =
class JobQueue extends EventEmitter
  constructor: ->
    # Handlers registered via `#register`.
    @handlers = []

    # All queued jobs indexed by job id.
    @idsToJobs = {}
    # All queued jobs in the order of enqueueing.
    @queue = []

    # Is execution of the next job on `process.nextTick` already scheduled?
    @scheduled = no

    # Is adding new jobs currently prohibited? This happens during execution of 'empty' event.
    @prohibition = no

    # The currently running job or `null`.
    @runningJob = null


  # Registers the given func to run for all requests that match the given scope. The second argument
  # is optional.
  register: (scope, options, func) ->
    if (typeof func is 'undefined') and (typeof options is 'function')
      func = options
      options = {}

    unless typeof scope is 'object'
      throw new TypeError("JobQueue.register(scope, [options], func) scope arg must be an object")
    unless typeof options is 'object'
      throw new TypeError("JobQueue.register(scope, [options], func) options arg must be an object")
    unless typeof func is 'function'
      throw new TypeError("JobQueue.register(scope, [options], func) func arg must be a function")

    handler = new JobHandler(scope, options, func)
    @handlers.push handler
    debug "Registered handler #{handler.id} with ID keys #{JSON.stringify(handler.idKeys)}"


  # Requests to perform a job with the given attributes.
  add: (request) ->
    if @prohibition
      throw new Error "Adding new jobs during 'empty' event is not allowed"
    if handler = @findHandler(request)
      job = new Job(request, handler)
      debug "Adding #{job}"

      if priorJob = @idsToJobs[job.id]
        debug "Found existing #{priorJob}"
        if priorJob.handler == handler
          job.consume(priorJob)
          @removeJobFromQueues priorJob
          debug "Merged the old job into the new one: #{job}"
        else
          throw new Error("Attempted to add a job that matches another job with the same id, but different handler: new job #{job}, prior job #{priorJob}")

      @addJobToQueue job
      @schedule()
    else
      throw new Error("No handlers match the added request: " + stringifyRequest(request))


  # Returns all requests waiting for execution, in the order they will be executed in.
  getQueuedRequests: ->
    (job.request for job in @queue)


  # use this to add more jobs when the current ones complete
  checkpoint: (func, description='') ->
    @once 'drain', =>
      debug "checkpoint(#{description})"
      func()
    @schedule()  # make sure it is called even if the queue is empty

  # this type of handler isn't allowed to add more jobs
  after: (func, description='') ->
    @once 'empty', =>
      debug "after(#{description})"
      func()
    @schedule()  # make sure it is called even if the queue is empty


  # ### JobQueue private methods


  # Finds a matching registered handler for the given request.
  findHandler: (request) ->
    for handler in @handlers
      if handler.matches(request)
        return handler
    null


  # Schedules execution of the next job in queue on `process.nextTick`.
  schedule: ->
    return if @scheduled or @runningJob
    @scheduled = yes

    process.nextTick =>
      @scheduled = no
      @executeNextJob()


  # Executes the next job in queue. When done, either schedules execution of the next job or emits
  # ‘drain’.
  executeNextJob: ->
    debug "executeNextJob"
    if job = @extractNextQueuedJob()
      @executeJob(job)
    else
      # handlers of 'drain' event are allowed to add more jobs
      @emit 'drain'
      if !@scheduled
        # handlers of 'empty' event aren't allowed to add more jobs; this event means "we're really actually drained"
        @prohibition = yes
        try
          @emit 'empty'
        finally
          @prohibition = no


  # Executes the given job. When done, either schedules execution of the next job or emits ‘drain’.
  # Assumes that the given job has already been removed from the queue.
  executeJob: (job) ->
    # Mark the job as running (and announce the news)
    @runningJob = job
    @emit 'running', job

    debug "Running #{job}"

    # Execute the job by running the handler function
    await job.handler.func.call(job, job.request, defer())

    # Mark the job as completed (and announce the news)
    @runningJob = null
    @emit 'complete', job

    # Fulfil our promise to reschedule or emit ‘drain’
    @schedule()


  # Add the given job to the underlying data structure.
  addJobToQueue: (job) ->
    @queue.push job
    @idsToJobs[job.id] = job


  # Remove the given job to the underlying data structure.
  removeJobFromQueues: (job) ->
    if (index = @queue.indexOf job) >= 0
      @queue.splice index, 1
    delete @idsToJobs[job.id]


  # Extract (i.e. remove and return) the next job from the underlying data structure.
  extractNextQueuedJob: ->
    if job = @queue.shift()
      delete @idsToJobs[job.id]
      job
    else
      null


# ### Job

# Wraps a request and associates it with a specific handler. Only instantiated by the JobQueue, but
# is visible to outside clients.
class Job
  constructor: (@request, @handler) ->
    @id = @handler.computeId(@request)

  consume: (priorJob) ->
    @handler.merge(@request, priorJob.request)

  toString: ->
    "Job(id = #{@id}, handler = #{@handler.id}, request = #{stringifyRequest @request})"


# ### JobHandler

# A private helper class that stores a handler registered via `JobQueue#register`, together with its
# scope and options.
class JobHandler
  constructor: (@scope, options, @func) ->
    @idKeys = options.idKeys || (key for own key of @scope).sort()
    @id = ("#{key}:#{value}" for own key, value of @scope).sort().join('-')

    @merge = options.merge || @defaultMerge

  matches: (request) ->
    for own key, value of @scope
      unless request[key] == value
        return no
    yes

  computeId: (request) ->
    ("#{key}:#{request[key]}" for key in @idKeys).join('-')

  defaultMerge: (request, priorRequest) ->
    for own key, oldValue of priorRequest
      newValue = request[key]
      if newValue != oldValue
        if (Array.isArray newValue) and (Array.isArray oldValue)
          newValue.splice 0, 0, oldValue...
          continue
        throw new Error "No default strategy for merging key '#{key}' of old request into new request; request id is #{request.id}, old request is #{stringifyRequest priorRequest}, new request is #{stringifyRequest request}"


# ### Helper functions (public API for debugging and testing purposes only)

# Returns a string representation of the given request for debugging and logging purposes.
JobQueue.stringifyRequest = stringifyRequest = (request) ->
  ("#{key}:#{stringifyValue value}" for own key, value of request).join('-')

# Returns a string representation of the given value. (We don't want to use JSON.stringify because
# it might throw, and this method should be useful for debugging errors that involve garbage
# arguments.)
JobQueue.stringifyValue = stringifyValue = (value) ->
  if typeof value is 'string'
    value
  else
    inspect(value)
