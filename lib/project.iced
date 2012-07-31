debug = require('debug')('livereload:core:project')
Path = require 'path'

{ EventEmitter } = require 'events'

CompilerOptions = require './projects/compileropts'
FileOptions     = require './projects/fileopts'


nextId = 1


class Project extends EventEmitter

  constructor: (@session, @vfs, @path) ->
    @name = Path.basename(@path)
    @id = "P#{nextId++}_#{@name}"

  setMemento: (@memento) ->
    # log.fyi
    debug "Loading project at #{@path} with memento #{JSON.stringify(@memento, null, 2)}"

    @compilationEnabled   = !!(@memento?.compilationEnabled ? 0)
    @disableLiveRefresh   = !!(@memento?.disableLiveRefresh ? 0)
    @enableRemoteWorkflow = !!(@memento?.enableRemoteServerWorkflow ? 0)
    @fullPageReloadDelay  = Math.floor((@memento?.fullPageReloadDelay ? 0.0) * 1000)
    @eventProcessingDelay = Math.floor((@memento?.eventProcessingDelay ? 0.0) * 1000)
    @postprocCommand      = (@memento?.postproc ? '').trim()
    @postprocEnabled      = !!(@memento?.postprocEnabled ? (@postprocCommand.length > 0))
    @rubyVersionId        = @memento?.rubyVersion || 'system'
    @excludedPaths        = @memento?.excludedPaths || []
    @customName           = @memento?.customName || ''
    @nrPathCompsInName    = @memento?.numberOfPathComponentsToUseAsName || 1  # 0 is intentionally turned into 1

    @compilerOptionsById = {}
    @fileOptionsByPath = {}

    for own compilerId, compilerOptionsMemento of @memento?.compilers || {}
      if compiler = @session.findCompilerById(compilerId)
        @compilerOptionsById[compilerId] = new CompilerOptions(compiler, compilerOptionsMemento)
        for own filePath, fileOptionsMemento of compilerOptionsMemento.files || {}
          @fileOptionsByPath[filePath] = new FileOptions(filePath, fileOptionsMemento)

    debug "@compilerOptionsById = " + JSON.stringify(([i, o.options] for i, o of @compilerOptionsById), null, 2)

    @postprocLastRunTime = 0
    @postprocGracePeriod = 500

    # @isLiveReloadBackend = (Path.normalize(@hive.fullPath) == Path.normalize(Path.join(__dirname, '../..')))
    # if @isLiveReloadBackend
    #   log.warn "LiveReload Development Mode enabled. Will restart myself on backend changes."
    #   @hive.requestMonitoring 'ThySelfAutoRestart', yes


  startMonitoring: ->
    unless @monitor
      @monitor = @vfs.watch(@path)
      @monitor.on 'change', (path) =>
        @emit 'change', path

  stopMonitoring: ->
    @monitor?.close()
    @monitor = null


module.exports = Project

