
{ MessageParser } = require './tool-output'


class Compiler
  constructor: (@plugin, @manifest) ->
    @name = @manifest.Name
    @parser = new MessageParser(@manifest)


exports.Compiler = Compiler
