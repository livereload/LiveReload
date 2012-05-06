Path = require 'path'
Job  = require '../app/jobs'

ReloadBrowserJob = require './reload_browser_job'
RunCompilerJob   = require './run_compiler_job'

module.exports = class ScheduleCompilationJob extends Job

  constructor: (@project, @paths) ->
    super @project.id

  merge: (sibling) ->
    @paths.pushAll sibling.paths

  execute: (callback) ->
    rootPaths = (@project.importGraph.resolveToRoots(path) for path in @paths).flatten(1)
    for path in rootPaths
      await @scheduleCompilationOrReload path, defer(err)
      return callback(err) if err

    callback(null)

  scheduleCompilationOrReload: (path, callback) ->
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
          LR.queue.add new RunCompilerJob @project, fileOptions
          # [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidEndCompilationNotification object:self];
      else
        outputPath = fileOptions.outputName
        LR.queue.add new ReloadBrowserJob [new ReloadBrowserJob.ReloadRequest(@project, @project.hive.absolutePathOf(outputPath), @project.hive.absolutePathOf(path))]
        LR.log.fyi "Broadcasting a fake change in #{outputPath} instead of #{path} because the file belongs to compiler #{fileOptions.compiler.name}"
    else
      LR.queue.add new ReloadBrowserJob [new ReloadBrowserJob.ReloadRequest(@project, absolutePath, null)]

    callback(null)
