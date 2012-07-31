debug = require('debug')('livereload:core:project')
Path  = require 'path'
Url   = require 'url'

{ EventEmitter } = require 'events'

CompilerOptions = require './compileropts'
FileOptions     = require './fileopts'

urlmatch = require '../utils/urlmatch'


nextId = 1


abspath = (path) ->
  if path.charAt(0) is '~'
    home = process.env.HOME
    if path.length is 1
      home
    else if path.charAt(1) is '/'
      Path.resolve(home, path.substr(2))
    else if m = path.match ///^ ~ ([^/]+) / (.*) $ ///
      other = Path.join(Path.dirname(home), m[1])  # TODO: resolve other users' home folders properly
      Path.resolve(other, m[2])
  else
    Path.resolve(path)


class Project extends EventEmitter

  constructor: (@session, @vfs, @path) ->
    @name = Path.basename(@path)
    @id = "P#{nextId++}_#{@name}"
    @fullPath = abspath(@path)

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
    @urls                 = @memento?.urls || []

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

  matchesUrl: (url) ->
    @urls.some (pattern) -> urlmatch(pattern, url)


  saveResourceFromWebInspector: (url, content, callback) ->
    components = Url.parse(url)

    await @vfs.findFilesMatchingSuffixInSubtree @path, components.pathname, null, defer(err, result)
    if err
      debug "findFilesMatchingSuffixInSubtree() returned error: #{err.message}"
      return callback(err)

    if result.bestMatch
      debug "findFilesMatchingSuffixInSubtree() found '#{result.bestMatch.path}'"
      fullPath = Path.join(@fullPath, result.bestMatch.path)

      debug "Saving #{content.length} characters into #{fullPath}..."
      await @vfs.writeFile fullPath, content, defer(err)
      if err
        debug "Saving failed: #{err.message}"
        return callback(err, no)

      debug "Saving succeeded!"
      return callback(err, yes)
    else
      debug "findFilesMatchingSuffixInSubtree() found #{result.bestMatches.length} matches."
      return callback(null, no)

module.exports = Project
