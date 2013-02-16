debug = require('debug')('livereload:core:postproc')

module.exports =
class PostProcPlugin

  metadata:
    apiVersion: 1
    name: 'livereload-postproc'

  jobPriorities: [
    'postproc'
  ]


  loadProject: (project, memento) ->
    project.postprocCommand = (memento?.postproc ? '').trim()
    project.postprocEnabled = !!(memento?.postprocEnabled ? (project.postprocCommand.length > 0))
    project.postprocLastRunTime = 0
    project.postprocGracePeriod = 500


  createSteps: (project) ->
    [new PostProcStep(project)]


class PostProcStep

  constructor: (@project) ->
    @id = 'postproc'
    @queue = @project.session.queue


  # LiveReload API

  initialize: () ->
    @queue.register { project: @project.id, action: 'postproc' }, @_perform.bind(@)

  schedule: (change) ->
    @queue.add { project: @project.id, action: 'postproc' }


  # internal

  _isAwaitingGracePeriod: ->
    (@project.postprocLastRunTime > 0) and (Date.now() < @project.postprocLastRunTime + @project.postprocGracePeriod)

  _isPostProcessingActive: ->
    @project.postprocEnabled && @project.postprocCommand

  _perform: (request, done) ->
    return done(null) unless @_isPostProcessingActive()
    if !@_isAwaitingGracePeriod()
      await @_runPostproc defer(err)
      @project.postprocLastRunTime = Date.now()
      done(err)
    else
      debug "Skipping post-processing: grace period of #{@project.postprocGracePeriod} ms hasn't expired"
      done(null)

  _runPostproc: (callback) ->
    parser = new @project.session.MessageParser({})
    tool = new @project.session.CommandLineTool {
      name: 'postproc'
      args: ['sh', '-c', @project.postprocCommand]
      cwd:  @project.fullPath
      parser
    }
    info =
      '$(projectDir)': @project.fullPath
    invocation = tool.createInvocation(info)

    action = { id: 'postproc', message: "Running #{@project.postprocCommand}" }
    @project.reportActionStart(action)
    invocation.once 'finished', =>
      @project.reportActionFinish(action)
      callback(null)
    invocation.run()
