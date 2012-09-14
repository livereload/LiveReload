{ EventEmitter } = require 'events'


module.exports =

class Run extends EventEmitter

  constructor: (@project, @change, @steps) ->
    @remainingSteps = @steps.slice()

  start: ->
    @performNextStep()

  finished: ->
    @emit 'finish'

  performNextStep: ->
    if @currentStep = @remainingSteps.shift()
      @emit 'step', this
      @currentStep.schedule()
    else
      return @finished()
