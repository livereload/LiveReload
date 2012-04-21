
{ MessageParser } = require './tool-output'


class Compiler
  constructor: (@plugin, @manifest) ->
    @name = @manifest.Name
    @parser = new MessageParser(@manifest)
    @enabledByDefault = !@manifest.optional


exports.Compiler = Compiler
