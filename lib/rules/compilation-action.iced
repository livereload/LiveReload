
Action = require './action'

module.exports =
class CompilationAction extends Action

  type: 'compile-file'

  constructor: (@compiler) ->
    super("compile-#{@compiler.id}", "Compile #{@compiler.name}")

  createDefaultRules: ->
    [{ src: '**/*.' + @compiler.extensions[0], dst: '**/*.' + @compiler.destinationExt }]
