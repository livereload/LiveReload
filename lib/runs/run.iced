{ EventEmitter } = require 'events'


module.exports =

class Run extends EventEmitter

  constructor: (@project, @change, @steps) ->
    @remainingSteps = @steps.slice()
    @queue = @project.session.queue

  start: ->
    @performNextStep()

  finished: ->
    @emit 'finish'

  performNextStep: ->
    if @currentStep = @remainingSteps.shift()
      @emit 'step', this
      @currentStep.schedule(@change)

      @queue.once 'drain', @_stepFinished.bind(@)
      @queue.checkDrain()
    else
      return @finished()

  _stepFinished: ->
    @performNextStep()
