Job = require '../app/jobs'

module.exports = class RunPostProcessingJob extends Job

  constructor: (@project, @changedPaths) ->
    super @project.id

  merge: (sibling) ->
    @changedPaths.pushAll sibling.changedPaths

  superfluous: ->
    !(@project.postprocEnabled && @project.postprocCommand)

  execute: (callback) ->
    if @project.postprocLastRunTime is 0 or (new Date().getTime() - @project.postprocLastRunTime) >= @project.postprocGracePeriod
      @runPostproc paths, defer()
      @project.postprocLastRunTime = new Date().getTime()
    else
      LR.console.puts "Skipping post-processing: grace period of #{@project.postprocGracePeriod} ms hasn't expired"
    callback(null)
