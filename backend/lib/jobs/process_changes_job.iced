Path = require 'path'

{ spawn } = require 'child_process'


subst = (value, args) ->
  if Object.isString(value)
    for own argName, argValue of args
      value = value.replace ///#{RegExp.escape(argName)}///g, argValue
    value
  else if Object.isArray(value)
    result = []
    for item in value
      # when $(something) arg value is an array, occurrences of $(something) in the source array are substituted by splicing
      if Object.isString(item) and (argValue = args[item])? and Object.isArray(argValue)
        result.push.apply(result, argValue)
      else
        result.push subst(item, args)
    return result
  else
    throw new Error("Unsupported value type in subst: #{typeof value}")

class ImportGraph

  findRootReferencingPaths: (path) ->
    null

class ReloadRequest

  constructor: (@path, @originalPath) ->


module.exports = class ProcessChangesJob

  constructor: (@project, @changedPaths) ->

  execute: (callback) ->
    @reloadRequests = []

    LR.log.fyi "change detected in #{@project.path}: #{JSON.stringify(@changedPaths)}\n"

    LR.console.puts "Changed: #{@changedPaths[0]}" + (if @changedPaths.length > 1 then " and #{@changedPaths.length - 1} others" else "")

    @updateImportGraph()
    importGraph = new ImportGraph()

    paths = (@resolveImportToRoots(importGraph, path) for path in @changedPaths).flatten(1)

    for path in paths
      await @runCompilers path, defer()

    await
      if @project.postprocEnabled && @project.postprocCommand
        if @project.postprocLastRunTime is 0 or (new Date().getTime() - @project.postprocLastRunTime) >= @project.postprocGracePeriod
          @runPostproc paths, defer()
          @project.postprocLastRunTime = new Date().getTime()
        else
          LR.console.puts "Skipping post-processing: grace period of #{@project.postprocGracePeriod} ms hasn't expired"

    isFullReload = no
    if @project.disableLiveRefresh
      isFullReload = yes
    else
      isFullReload = paths.any (path) => !path.match /\.(jpe?g|gif|png|css)$/

    broadcastChangesToBrowser = =>
      LR.stats.incr 'stat.reloads'
      for request in @reloadRequests
        LR.websockets.sendReloadCommand
          path:            request.path
          originalPath:    request.originalPath
          liveCSS:        !@project.disableLiveRefresh
          enableOverride:  @project.enableRemoteServerWorkflow

    if isFullReload and @project.fullPageReloadDelay > 0
      setTimeout broadcastChangesToBrowser, @project.fullPageReloadDelay
    else
      broadcastChangesToBrowser()

    callback(null)

  updateImportGraph: ->

  resolveImportToRoots: (importGraph, path) ->
    if roots = importGraph.findRootReferencingPaths(path)
      roots
    else
      [ path ]

  runCompilers: (path, callback) ->
    await @project.obtainFileOptions path, defer(err, fileOptions)
    return callback(err) if err

    absolutePath = @project.hive.absolutePathOf(path)
    await Path.exists absolutePath, defer(exists)
    unless exists
      return callback(null)  # not interested in compiling or refreshing deleted files

    if fileOptions.compiler
      LR.log.fyi "Detected that #{path} belongs to compiler #{fileOptions.compiler.name}, compilationEnabled = #{@project.compilationEnabled}"
      LR.stats.incrGroup "stat.compiler",    fileOptions.compiler.id

      compilerOptions = @project.obtainCompilerOptions(fileOptions.compiler, @project.compilationEnabled)
      if @project.compilationEnabled && compilerOptions.enabled
        if !fileOptions.enabled
          LR.log.fyi "Ignoring a change in #{path} because it is disabled"
        else if fileOptions.compiler.needsOutputDirectory && !fileOptions.outputDir
          LR.log.fyi "Ignoring a change in #{path} because no output dir is set"
        else
          # [[NSNotificationCenter defaultCenter] postNotificationName:ProjectWillBeginCompilationNotification object:self];
          await @runCompiler fileOptions, compilerOptions, defer()
          # [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidEndCompilationNotification object:self];

          LR.stats.incrGroup "stat.compilation", fileOptions.compiler.id
      else
        outputPath = fileOptions.outputName
        @reloadRequests.push new ReloadRequest(@project.hive.absolutePathOf(outputPath), @project.hive.absolutePathOf(path))
        LR.log.fyi "Broadcasting a fake change in #{outputPath} instead of #{path} because the file belongs to compiler #{fileOptions.compiler.name}"
    else
      @reloadRequests.push new ReloadRequest(absolutePath, null)

    callback(null)


  runCompiler: (fileOptions, compilerOptions, callback) ->
    outputPath = if fileOptions.compiler.needsOutputDirectory
      Path.join(fileOptions.outputDir, fileOptions.outputName)
    else
      Path.join(Path.dirname(fileOptions.path), fileOptions.outputName)  # just a dummy path

    sourceAbsPath = @project.hive.absolutePathOf(fileOptions.path)
    outputAbsPath = @project.hive.absolutePathOf(outputPath)

    LR.log.fyi "runCompiler for #{fileOptions.path} into #{outputPath}, compiler #{fileOptions.compiler.name}"

    info =
      "$(ruby)":         "/usr/bin/ruby"
      "$(node)":         process.argv[0]
      "$(plugin)":       fileOptions.compiler.plugin.folder
      "$(project_dir)":  @project.hive.fullPath

      "$(src_path)":     sourceAbsPath
      "$(src_file)":     Path.basename(sourceAbsPath)
      "$(src_dir)":      Path.dirname(sourceAbsPath)
      "$(src_rel_path)": fileOptions.path

      "$(dst_path)":     outputAbsPath
      "$(dst_file)":     Path.basename(outputAbsPath)
      "$(dst_dir)":      Path.dirname(outputAbsPath)
      "$(dst_rel_path)": outputPath

    info["$(additional)"] = []

    LR.log.fyi "Substituting info: #{JSON.stringify(info, null, 2)}"

    args = subst(fileOptions.compiler.commandLine, info)
    LR.log.fyi "Invoking command line: #{JSON.stringify(args)}"

    command = args.shift()
    subprocess = spawn(command, args, cwd: @project.hive.fullPath, env: process.env)

    stdout = []
    stderr = []
    subprocess.stdout.setEncoding 'utf8'
    subprocess.stderr.setEncoding 'utf8'
    subprocess.stdout.on 'data', (data) =>
      stdout.push data
    subprocess.stderr.on 'data', (data) =>
      stderr.push data

    await subprocess.on 'exit', defer(exitCode)

    stdout = stdout.join('')
    stderr = stderr.join('')

    LR.log.fyi "Command outputs: " + JSON.stringify({ stdout, stderr, exitCode }, null, 2)

    if exitCode is 127
      return callback("Cannot invoke compiler")

    callback(null)


    # ToolOutput *compilerOutput = nil;
    # [fileOptions.compiler compile:relativePath into:outputPath under:rootPath inProject:self with:compilationOptions compilerOutput:&compilerOutput];
    # if (compilerOutput) {
    #     compilerOutput.project = self;

    #     [[[[ToolOutputWindowController alloc] initWithCompilerOutput:compilerOutput key:path] autorelease] show];
    # } else {
    #     [ToolOutputWindowController hideOutputWindowWithKey:path];
    # }




  runPostproc: (paths, callback) ->
    # NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
    #                              @"/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby", @"$(ruby)",
    #                              [[NSBundle mainBundle] pathForResource:@"node" ofType:nil], @"$(node)",
    #                              _path, @"$(project_dir)",
    #                              nil];

    # NSString *command = [_postProcessingCommand stringBySubstitutingValuesFromDictionary:info];
    # NSString *shell = DetermineShell();
    # NSLog(@"Running post-processing command: %@", command);

    # NSString *runDirectory = _path;
    # NSString *prefix = @"which rvm >/dev/null || source \"$HOME/.rvm/scripts/rvm\"; ";
    # NSArray *shArgs = [NSArray arrayWithObjects:@"--login",@"-i",@"-c", [prefix stringByAppendingString:command], nil];

    # NSError *error = nil;
    # NSString *pwd = [[NSFileManager defaultManager] currentDirectoryPath];
    # [[NSFileManager defaultManager] changeCurrentDirectoryPath:runDirectory];
    # const char *project_path = [self.path UTF8String];
    # console_printf("Post-proc exec: %s --login -c \"%s\"", [shell UTF8String], str_collapse_paths([command UTF8String], project_path));
    LR.console.puts "Post-proc exec"
    # NSString *output = [NSTask stringByLaunchingPath:shell
    #                                    withArguments:shArgs
    #                                            error:&error];
    # [[NSFileManager defaultManager] changeCurrentDirectoryPath:pwd];

    # if ([output length] > 0) {
    #     console_printf("\n%s\n\n", str_collapse_paths([output UTF8String], project_path));
    #     NSLog(@"Post-processing output:\n%@\n", output);
    # }
    # if (error) {
    #     console_printf("Post-processor failed.");
    #     NSLog(@"Error: %@", [error description]);
    # }

