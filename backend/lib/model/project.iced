
Path = require 'path'

nextProjectId = 1


decodeExternalRelativeDir = (dir) ->
  switch dir
    when ''  then null
    when '.' then ''
    else dir


class FileOptions

  constructor: (@path, @memento={}) ->
    @enabled = @memento.enabled ? yes
    @outputDir = decodeExternalRelativeDir(@memento.output_dir ? '')
    @outputNameMask = @memento.output_file ? ''


class CompilerOptions

  constructor: (compiler, @memento={}) ->
    @enabled = (@memento?.enabled2 ? compiler?.enabledByDefault) ? no
    @additionalArguments = @memento?.additionalArguments || ''
    @options = @memento?.options || {}

    @fileOptions = {}
    for own filePath, fileOptionsMemento of @memento?.files || {}
      @fileOptions[filePath] = new FileOptions(filePath, fileOptionsMemento)


class Project
  constructor: (@workspace, @path, @memento={}) ->
    @id   = "P#{nextProjectId++}"
    @name = Path.basename(@path)

    @hive = LR.fsmanager.createHive(@path)
    @hive.on 'change', (paths, callback) =>
      @handleChange(paths, callback)

    @compilationEnabled         = !!(@memento?.compilationEnabled ? 0)
    @disableLiveRefresh         = !!(@memento?.disableLiveRefresh ? 0)
    @enableRemoteServerWorkflow = !!(@memento?.enableRemoteServerWorkflow ? 0)
    @fullPageReloadDelay        = @memento?.fullPageReloadDelay ? 0.0
    @eventProcessingDelay       = @memento?.eventProcessingDelay ? 0.0
    @postprocCommand            = (@memento?.postproc ? '').trim()
    @postprocEnabled            = !!(@memento?.postprocEnabled ? (@postprocCommand.length > 0))
    @rubyVersionIdentifier      = @memento?.rubyVersion || 'system'
    @excludedPaths              = @memento?.excludedPaths || []
    @customName                 = @memento?.customName || ''
    @numberOfPathComponentsToUseAsName = @memento?.numberOfPathComponentsToUseAsName || 1  # 0 is intentionally turned into 1

    @compilerOptions = {}
    for own compilerId, compilerOptionsMemento of @memento?.compilers || {}
      @compilerOptions[compilerId] = new CompilerOptions(compilerOptionsMemento)

  dispose: ->
    @hive.dispose()

  toJSON: ->
    { @id, @name, @path }

  toMemento: ->
    { @path }

  handleChange: (paths, callback) ->
    LR.log.fyi "change detected in #{@path}: #{JSON.stringify(paths)}\n"
    for path in paths
      LR.websockets.sendReloadCommand { path }
    callback(null)

module.exports = { Project }
