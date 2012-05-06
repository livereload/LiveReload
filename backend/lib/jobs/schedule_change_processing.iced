
DevModeRestartJob      = require './dev_mode_restart_job'
AnalyzeImportsJob      = require './analyze_imports_job'
ScheduleCompilationJob = require './schedule_compilation_job'
RunPostProcessingJob   = require './run_postproc_job'


scheduleChangeProcessing = (project, changedPaths, callback) ->
    LR.log.fyi "change detected in #{project.path}: #{JSON.stringify(changedPaths)}\n"
    LR.console.puts "Changed: #{changedPaths[0]}" + (if changedPaths.length > 1 then " and #{changedPaths.length - 1} others" else "")

    if project.isLiveReloadBackend and changedPaths.some((path) => path.match(/\.(js|json)$/))
      LR.queue.add new DevModeRestartJob

    for path in changedPaths
      LR.queue.add new AnalyzeImportsJob project, path
    LR.queue.add new ScheduleCompilationJob project, changedPaths
    LR.queue.add new RunPostProcessingJob project, changedPaths

    callback(null)


module.exports = { scheduleChangeProcessing }
