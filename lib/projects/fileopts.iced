Path = require 'path'


decodeExternalRelativeDir = (dir) ->
  switch dir
    when ''  then null
    when '.' then ''
    else dir

encodeExternalRelativeDir = (dir) ->
  switch dir
    when null then ''
    when ''   then '.'
    else dir


class FileOptions

  constructor: (@project, @path, memento={}) ->
    @initialized = no
    @enabled = memento.enabled ? yes
    @compiler = null

    @setMemento memento


    Object.defineProperty this, 'outputName', get: => @outputNameForMask(@outputNameMask)

  Object.defineProperty @::, 'relpath',
    get: -> @path

  Object.defineProperty @::, 'fullPath',
    get: -> Path.join(@project.fullPath, @path)

  Object.defineProperty @::, 'destDir',
    get:     -> @outputDir
    set: (v) -> @outputDir = v

  Object.defineProperty @::, 'fullDestDir',
    get:     -> Path.join(@project.fullPath, @destDir)
    set: (v) -> @destDir = Path.relative(@project.fullPath, v)

  Object.defineProperty @::, 'destRelPath',
    get: -> Path.join(@outputDir, (@outputNameMask and @outputNameForMask(@outputNameMask) or "<none>"))

  Object.defineProperty @::, 'isImported',
    get: -> @project.imports.hasIncomingEdges(@path)

  setMemento: (@memento) ->
    @exists = @memento.exists ? null

    if @memento.dst
      @outputDir = decodeExternalRelativeDir Path.dirname(@memento.dst)

      @outputNameMask = Path.basename(@memento.dst)
      @outputNameMask = '' if @outputNameMask is '<none>'

    else
      @outputDir = decodeExternalRelativeDir(@memento.output_dir ? '')
      @outputDir or= (if Path.dirname(@path) == '.' then '' else Path.dirname(@path))

      @outputNameMask = @memento.output_file ? ''

  makeMemento: ->
    {
      src: @path
      dst: Path.join(@outputDir, (@outputNameMask or "<none>"))
      exists: (if @exists then undefined else no)
      compiler: @compiler?.id or undefined
    }

  outputNameForMask: (mask) ->
    sourceBaseName = Path.basename(@path, Path.extname(@path))

    # TODO
    # // handle a mask like "*.php" applied to a source file named like "foo.php.jade"
    # while ([destinationNameMask pathExtension].length > 0 && [sourceBaseName pathExtension].length > 0 && [[destinationNameMask pathExtension] isEqualToString:[sourceBaseName pathExtension]]) {
    #     destinationNameMask = [destinationNameMask stringByDeletingPathExtension];
    # }

    mask.replace '*', sourceBaseName


module.exports = FileOptions
