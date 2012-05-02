
Path = require 'path'

R = require '../reactive'

nextProjectId = 1

ProcessChangesJob = require '../jobs/process_changes_job'
{ EventEmitter }  = require 'events'


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

    Object.defineProperty this, 'outputName', get: => @outputNameForMask(@outputNameMask)

  outputNameForMask: (mask) ->
    sourceBaseName = Path.basename(@path, Path.extname(@path))

    # TODO
    # // handle a mask like "*.php" applied to a source file named like "foo.php.jade"
    # while ([destinationNameMask pathExtension].length > 0 && [sourceBaseName pathExtension].length > 0 && [[destinationNameMask pathExtension] isEqualToString:[sourceBaseName pathExtension]]) {
    #     destinationNameMask = [destinationNameMask stringByDeletingPathExtension];
    # }

    mask.replace '*', sourceBaseName



class CompilerOptions

  constructor: (@compiler, @memento={}) ->
    @enabled = (@memento?.enabled2 ? @compiler.enabledByDefault) ? no
    @additionalArguments = @memento?.additionalArguments || ''
    @options = @memento?.options || {}


class Project extends R.Entity
  constructor: (@workspace, @path, @memento={}) ->
    @name = Path.basename(@path)

    super(@name)
    @id = @__uid

    @hive = LR.fsmanager.createHive(@path)
    @hive.on 'change', (paths, callback) =>
      @handleChange(paths, callback)

    LR.log.fyi "Adding project at #{@path} with memento #{JSON.stringify(@memento, null, 2)}"

    @__defprop 'compilationEnabled',         !!(@memento?.compilationEnabled ? 0)
    @__defprop 'disableLiveRefresh',         !!(@memento?.disableLiveRefresh ? 0)
    @__defprop 'enableRemoteServerWorkflow', !!(@memento?.enableRemoteServerWorkflow ? 0)
    @__defprop 'fullPageReloadDelay',        Math.floor((@memento?.fullPageReloadDelay ? 0.0) * 1000)
    @__defprop 'eventProcessingDelay',       Math.floor((@memento?.eventProcessingDelay ? 0.0) * 1000)
    @__defprop 'postprocCommand',            (@memento?.postproc ? '').trim()
    @__defprop 'postprocEnabled',            !!(@memento?.postprocEnabled ? (@postprocCommand.length > 0))
    @__defprop 'rubyVersionIdentifier',      @memento?.rubyVersion || 'system'
    @__defprop 'excludedPaths',              @memento?.excludedPaths || []
    @__defprop 'customName',                 @memento?.customName || ''
    @__defprop 'numberOfPathComponentsToUseAsName', @memento?.numberOfPathComponentsToUseAsName || 1  # 0 is intentionally turned into 1

    @compilerOptionsById = {}
    @fileOptionsByPath = {}

    for own compilerId, compilerOptionsMemento of @memento?.compilers || {}
      if compiler = LR.pluginManager.compilersById[compilerId]
        @compilerOptionsById[compilerId] = new CompilerOptions(compiler, compilerOptionsMemento)
      for own filePath, fileOptionsMemento of compilerOptionsMemento.files || {}
        @fileOptionsByPath[filePath] = new FileOptions(filePath, fileOptionsMemento)

    @postprocLastRunTime = 0
    @postprocGracePeriod = 500

    @isLiveReloadBackend = (Path.normalize(@hive.fullPath) == Path.normalize(Path.join(__dirname, '../..')))
    if @isLiveReloadBackend
      LR.log.wtf "LiveReload Development Mode enabled. Will restart myself on backend changes."
      @hive.requestMonitoring 'ThySelfAutoRestart', yes

  'automatically request monitoring for processing': ->
     @hive.requestMonitoring 'processing', (@compilationEnabled || @postprocEnabled)


  dispose: ->
    @hive.dispose()

  toJSON: ->
    { @id, @name, @path }

  toMemento: ->
    { @path }

  handleChange: (paths, callback) ->
    new ProcessChangesJob(this, paths).execute(callback)

  _modified: ->
    @emit 'modified'

  obtainCompilerOptions: (compiler, createIfDoesNotExist) ->
    compilerOptions = @compilerOptionsById[compiler.id]
    if !compilerOptions && createIfDoesNotExist
      @compilerOptionsById[compiler.id] = compilerOptions = new CompilerOptions(compiler)
      @_modified()
    compilerOptions

  obtainFileOptions: (path, callback) ->
    fileOptions = @fileOptionsByPath[path]
    unless fileOptions
      fileOptions = new FileOptions(path)
      await @initializeFileOptions fileOptions, defer(err)
      if err
        return callback(err)
      if fileOptions.compiler
        @fileOptionsByPath[path] = fileOptions
        @_modified()
    callback(null, fileOptions)

  initializeFileOptions: (fileOptions, callback) ->
    sourcePath = fileOptions.path
    ext = Path.extname(sourcePath)

    # TODO: properly handle SASS/Compass here
    fileOptions.compiler = LR.pluginManager.compilers.find (compiler) =>
      (ext in compiler.srcExts) && compiler.id != 'compass'

    if fileOptions.compiler
      unless fileOptions.outputNameMask
        bareName = Path.basename(sourcePath, Path.extname(sourcePath))
        fileOptions.outputNameMask =
          if no && Path.extname(bareName) && tree && tree.containsFileNamed(bareName)
            bareName
          else
            "*" + fileOptions.compiler.dstExt

      unless fileOptions.outputDir?
        await @guessOutputDirectory fileOptions, defer(err, guessedDirectory)
        if err
          return callback(err)
        fileOptions.outputDir = guessedDirectory

    callback(null)


  guessOutputDirectory: (fileOptions, callback) ->
    sourcePath = fileOptions.path

    # 1) destination file already exists?
    # NSString *derivedName = fileOptions.destinationName;
    # NSString *derivedPath = [self.tree pathOfFileNamed:derivedName];
    # if (derivedPath) {
    #     guessedDirectory = [derivedPath stringByDeletingLastPathComponent];
    #     NSLog(@"Guessed output directory for %@ by existing output file %@", sourcePath, derivedPath);
    # }

    # 2) other files in the same folder have a common destination path?
    # NSString *sourceDirectory = [sourcePath stringByDeletingLastPathComponent];
    # NSArray *otherFiles = [[compilationOptions.compiler pathsOfSourceFilesInTree:self.tree] filteredArrayUsingBlock:^BOOL(id value) {
    #     return ![sourcePath isEqualToString:value] && [sourceDirectory isEqualToString:[value stringByDeletingLastPathComponent]];
    # }];
    # if ([otherFiles count] > 0) {
    #     NSArray *otherFileOptions = [otherFiles arrayByMappingElementsUsingBlock:^id(id otherFilePath) {
    #         return [compilationOptions optionsForFileAtPath:otherFilePath create:NO];
    #     }];
    #     NSString *common = [FileCompilationOptions commonOutputDirectoryFor:otherFileOptions inProject:self];
    #     if ([common isEqualToString:@"__NONE_SET__"]) {
    #         // nothing to figure it from
    #     } else if (common == nil) {
    #         // different directories, something complicated is going on here;
    #         // don't try to be too smart and just give up
    #         NSLog(@"Refusing to guess output directory for %@ because other files in the same directory have varying output directories", sourcePath);
    #         goto skipGuessing;
    #     } else {
    #         guessedDirectory = common;
    #         NSLog(@"Guessed output directory for %@ based on configuration of other files in the same directory", sourcePath);
    #     }
    # }

    # 3) are we in a subfolder with one of predefined 'output' names? (e.g. css/something.less)
    # NSSet *magicNames = [NSSet setWithArray:compilationOptions.compiler.expectedOutputDirectoryNames];
    # guessedDirectory = [self enumerateParentFoldersFromFolder:[sourcePath stringByDeletingLastPathComponent] with:^(NSString *folder, NSString *relativePath, BOOL *stop) {
    #     if ([magicNames containsObject:[folder lastPathComponent]]) {
    #         NSLog(@"Guessed output directory for %@ to be its own parent folder (%@) based on being located inside a folder with magical name %@", sourcePath, [sourcePath stringByDeletingLastPathComponent], folder);
    #         return (id)[sourcePath stringByDeletingLastPathComponent];
    #     }
    #     return (id)nil;
    # }];

    # 4) is there a sibling directory with one of predefined 'output' names? (e.g. smt/css/ for smt/src/foo/file.styl)
    # NSSet *magicNames = [NSSet setWithArray:compilationOptions.compiler.expectedOutputDirectoryNames];
    # guessedDirectory = [self enumerateParentFoldersFromFolder:[sourcePath stringByDeletingLastPathComponent] with:^(NSString *folder, NSString *relativePath, BOOL *stop) {
    #     NSString *parent = [folder stringByDeletingLastPathComponent];
    #     NSFileManager *fm = [NSFileManager defaultManager];
    #     for (NSString *magicName in magicNames) {
    #         NSString *possibleDir = [parent stringByAppendingPathComponent:magicName];
    #         BOOL isDir = NO;
    #         if ([fm fileExistsAtPath:[_path stringByAppendingPathComponent:possibleDir] isDirectory:&isDir])
    #             if (isDir) {
    #                 // TODO: decide whether or not to append relativePath based on existence of other files following the same convention
    #                 NSString *guess = [possibleDir stringByAppendingPathComponent:relativePath];
    #                 NSLog(@"Guessed output directory for %@ to be %@ based on a sibling folder with a magical name %@", sourcePath, guess, possibleDir);
    #                 return (id)guess;
    #             }
    #     }
    #     return (id)nil;
    # }];

    # 5) if still nothing, put the result in the same folder
    return callback(null, Path.dirname(sourcePath))


module.exports = { Project }
