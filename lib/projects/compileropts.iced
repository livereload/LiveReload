
class CompilerOptions

  constructor: (@compiler, @memento={}) ->
    @enabled = (@memento?.enabled2 ? @compiler.enabledByDefault) ? no
    @additionalArguments = @memento?.additionalArguments || ''
    @options = @memento?.options || {}

module.exports = CompilerOptions
