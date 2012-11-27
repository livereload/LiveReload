debug = require('debug')('livereload:core')
{ EventEmitter } = require 'events'


module.exports =

class Run extends EventEmitter

  constructor: (@project, @change, @steps) ->
    @remainingSteps = @steps.slice()
    @queue = @project.session.queue

  toString: ->
    paths = @change.paths
    desc = paths.slice(0, 2).join(',') + (if paths.length > 2 then ",…" else "")
    "Run(#{desc})"

  start: ->
    @performNextStep()

  finished: ->
    @emit 'finish'

  performNextStep: ->
    if @currentStep = @remainingSteps.shift()
      debug "Run performing step: #{@currentStep.constructor.name} #{@currentStep}"
      @emit 'step', this
      @currentStep.schedule(@change)

      @queue.checkpoint @_stepFinished.bind(@), "#{this}.stepFinished"
    else
      debug "Run finished."
      return @finished()

  _stepFinished: ->
    @performNextStep()
