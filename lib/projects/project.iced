debug = require('debug')('livereload:core:project')
Path  = require 'path'
Url   = require 'url'
R     = require 'reactive'
urlmatch = require 'urlmatch'
fsmonitor = require 'fsmonitor'

CompilerOptions = require './compileropts'
FileOptions     = require './fileopts'

Run      = require '../runs/run'


RegExp_escape = (s) ->
  s.replace /// [-/\\^$*+?.()|[\]{}] ///g, '\\$&'


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


class Project extends R.Model

  schema:
    compilationEnabled:       { type: Boolean }

    # always do a full page reload
    disableLiveRefresh:       { type: Boolean }

    # enables URL overriding when CSS modifications are detected
    enableRemoteWorkflow:     { type: Boolean }

    # in ms
    fullPageReloadDelay:      { type: Number }
    eventProcessingDelay:     { type: Number }

    rubyVersionId:            { type: String }

    # paths we should never monitor or enumerate
    excludedPaths:            { type: Array }

    # URL wildcards that correspond to this project's files
    urls:                     { type: Array }

    customName:               { type: String }
    nrPathCompsInName:        { type: 'int' }


  constructor: (@session, @vfs, @path) ->
    super()
    @name = Path.basename(@path)
    @id = "P#{nextId++}_#{@name}"
    @fullPath = abspath(@path)
    @analyzer = new (require './analyzer')(this)

    @watcher = fsmonitor.watch(@fullPath, null)
    debug "Monitoring for changes: folder = %j", @fullPath
    @watcher.on 'change', (change) =>
      debug "Detected change:\n#{change}"
      @handleChange @vfs, @fullPath, change.addedFiles.concat(change.modifiedFiles)

  setMemento: (@memento) ->
    # log.fyi
    debug "Loading project at #{@path} with memento #{JSON.stringify(@memento, null, 2)}"

    @compilationEnabled   = !!(@memento?.compilationEnabled ? 0)
    @disableLiveRefresh   = !!(@memento?.disableLiveRefresh ? 0)
    @enableRemoteWorkflow = !!(@memento?.enableRemoteServerWorkflow ? 0)
    @fullPageReloadDelay  = Math.floor((@memento?.fullPageReloadDelay ? 0.0) * 1000)
    @eventProcessingDelay = Math.floor((@memento?.eventProcessingDelay ? 0.0) * 1000)
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

    for plugin in @session.plugins
      plugin.loadProject? this, @memento

    @steps = []
    for plugin in @session.plugins
      for step in plugin.createSteps?(this) || []
        step.initialize()
        @steps.push step

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

  matchesVFS: (vfs) ->
    vfs is @vfs

  matchesPath: (root, path) ->
    @vfs.isSubpath(@fullPath, Path.join(root, path))

  filterPaths: (root, paths) ->
    (path for path in paths when @matchesPath(root, path))

  matchesUrl: (url) ->
    components = Url.parse(url)
    if components.protocol is 'file:'
      return components.pathname.substr(0, @fullPath.length) == @fullPath
    @urls.some (pattern) -> urlmatch(pattern, url)

  handleChange: (vfs, root, paths) ->
    return unless @matchesVFS(vfs)

    paths = @filterPaths(root, paths)
    return if paths.length is 0

    change = { paths, pathsToRefresh: paths }

    @analyzer.update(paths)

    run = new Run(this, change, @steps)
    debug "Project.handleChange: created run for %j", paths

    @session.queue.once 'drain', =>
      pathsToProcess = []
      for path in paths
        if (sources = @imports.findSources(path)) and (sources.length > 0) and ((sources.length != 1) or (sources[0] != path))
          debug "Will process #{sources.join(', ')} instead of imported #{path}"
          pathsToProcess.push.apply(pathsToProcess, sources)
        else
          pathsToProcess.push(path)

      change.paths = change.pathsToRefresh = pathsToProcess

      run.once 'finish', =>
        debug "Project.handleChange: finished run for %j", paths
        @emit 'run.finish', run
      run.start()
    @session.queue.checkDrain()

    return run

  patchSourceFile: (oldCompiled, newCompiled, callback) ->
    oldLines = oldCompiled.trim().split("\n")
    newLines = newCompiled.trim().split("\n")

    oldLen = oldLines.length
    newLen = newLines.length
    minLen = Math.min(oldLen, newLen)

    prefixLen = 0
    prefixLen++ while (prefixLen < minLen) and (oldLines[prefixLen] == newLines[prefixLen])

    maxSuffixLen = minLen - prefixLen
    suffixLen = 0
    suffixLen++ while (suffixLen < maxSuffixLen) and (oldLines[oldLen - suffixLen - 1] == newLines[newLen - suffixLen - 1])

    if minLen - prefixLen - suffixLen != 1
      debug "Cannot patch source file: minLen = #{minLen}, prefixLen = #{prefixLen}, suffixLen = #{suffixLen}"
      return callback(null)

    oldLine = oldLines[prefixLen]
    newLine = newLines[prefixLen]

    debug "oldLine = %j", oldLine
    debug "newLine = %j", newLine

    SELECTOR_RE = /// ([\w-]+) \s* : (.*?) [;}] ///
    unless (om = oldLine.match SELECTOR_RE) and (nm = newLine.match SELECTOR_RE)
      debug "Cannot match selector regexp"
      return callback(null)

    oldSelector = om[1]; oldValue = om[2].trim()
    newSelector = nm[1]; newValue = nm[2].trim()

    debug "oldSelector = #{oldSelector}, oldValue = '#{oldValue}'"
    debug "newSelector = #{newSelector}, newValue = '#{newValue}'"

    unless oldSelector == newSelector
      debug "Refusing to change oldSelector = #{oldSelector} into newSelector = #{newSelector}"
      return callback(null)

    sourceRef = null
    lineno = prefixLen - 1
    while lineno >= 0
      if m = newLines[lineno].match ///  /\* \s* line \s+ (\d+) \s* [,:] (.*?) \*/ ///
        sourceRef = { path: m[2].trim(), line: parseInt(m[1].trim(), 10) }
        break
      --lineno

    unless sourceRef
      debug "patchSourceFile() cannot find source ref before line #{prefixLen}"
      return callback(null)

    debug "patchSourceFile() foudn source ref %j", sourceRef

    await @vfs.findFilesMatchingSuffixInSubtree @path, sourceRef.path, null, defer(err, srcResult)
    if err
      debug "findFilesMatchingSuffixInSubtree() for src file '#{sourceRef.path}' returned error: #{err.message}"
      return callback(err)

    unless srcResult.bestMatch
      debug "findFilesMatchingSuffixInSubtree() for src file '#{sourceRef.path}' found #{result.bestMatches.length} matches."
      return callback(null)

    fullSrcPath = Path.join(@fullPath, srcResult.bestMatch.path)
    debug "findFilesMatchingSuffixInSubtree() for src file '#{sourceRef.path}' found #{fullSrcPath}"

    await @vfs.readFile fullSrcPath, 'utf8', defer(err, oldSource)
    return callback(err) if err

    REPLACEMENT_RE = /// #{RegExp_escape(oldSelector)} (\s* (?: : \s* )?) #{RegExp_escape(oldValue)} ///

    srcLines = oldSource.split "\n"

    debug "Got #{srcLines.length} lines, looking starting from line #{sourceRef.line - 1}"

    lineno = sourceRef.line - 1
    found = no
    while lineno < srcLines.length
      line = srcLines[lineno ]
      debug "Considering line #{lineno}: #{line}"

      if m = line.match REPLACEMENT_RE
        debug "Matched!"

        line = line.replace REPLACEMENT_RE, (_, sep) -> "#{newSelector}#{sep}#{newValue}"
        srcLines[lineno] = line
        found = yes
        break

      ++lineno

    unless found
      debug "Nothing matched :-("
      return callback null

    newSource = srcLines.join "\n"

    debug "Saving patched source file..."

    await @vfs.writeFile fullSrcPath, newSource, defer(err)
    return callback err if err

    callback null



  saveResourceFromWebInspector: (url, content, callback) ->
    components = Url.parse(url)

    await @vfs.findFilesMatchingSuffixInSubtree @path, components.pathname, null, defer(err, result)
    if err
      debug "findFilesMatchingSuffixInSubtree() returned error: #{err.message}"
      return callback(err)

    if result.bestMatch
      debug "findFilesMatchingSuffixInSubtree() found '#{result.bestMatch.path}'"
      fullPath = Path.join(@fullPath, result.bestMatch.path)

      await @vfs.readFile fullPath, 'utf8', defer(err, oldContent)
      if err
        debug "Loading (pre-save) failed: #{err.message}"
        return callback(err, no)

      debug "Saving #{content.length} characters into #{fullPath}..."
      await @vfs.writeFile fullPath, content, defer(err)
      if err
        debug "Saving failed: #{err.message}"
        return callback(err, no)

      debug "Saving succeeded!"

      if oldContent.match ///  /\* \s* line \s+ \d+ \s* [,:] (.*?) \*/ ///
        await @patchSourceFile oldContent, content, defer(err)
        if err
          debug "patchSourceFile() failed: #{err.message}"
          return callback(err, yes)

      return callback(null, yes)

    else
      debug "findFilesMatchingSuffixInSubtree() found #{result.bestMatches.length} matches."
      return callback(null, no)

module.exports = Project
