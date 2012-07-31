Path = require 'path'


decodeExternalRelativeDir = (dir) ->
  switch dir
    when ''  then null
    when '.' then ''
    else dir


class FileOptions

  constructor: (@path, @memento={}) ->
    @initialized = no
    @enabled = @memento.enabled ? yes
    @outputDir = decodeExternalRelativeDir(@memento.output_dir ? '')
    @outputNameMask = @memento.output_file ? ''

    # TODO XXX HACK removeme
    @outputDir = (if Path.dirname(@path) == '.' then '' else Path.dirname(@path))

    Object.defineProperty this, 'outputName', get: => @outputNameForMask(@outputNameMask)

  outputNameForMask: (mask) ->
    sourceBaseName = Path.basename(@path, Path.extname(@path))

    # TODO
    # // handle a mask like "*.php" applied to a source file named like "foo.php.jade"
    # while ([destinationNameMask pathExtension].length > 0 && [sourceBaseName pathExtension].length > 0 && [[destinationNameMask pathExtension] isEqualToString:[sourceBaseName pathExtension]]) {
    #     destinationNameMask = [destinationNameMask stringByDeletingPathExtension];
    # }

    mask.replace '*', sourceBaseName


module.exports = FileOptions
