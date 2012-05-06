Path = require 'path'
Job  = require '../app/jobs'

{ spawn } = require 'child_process'
{ subst } = require '../util/tool_invocation'

module.exports = class RunCompilerJob extends Job

  constructor: (@project, @fileOptions) ->
    super [@project.id, @fileOptions.path]

  merge: (sibling) ->

  execute: (callback) ->
    LR.stats.incrGroup "stat.compilation", @fileOptions.compiler.id

    outputPath = if @fileOptions.compiler.needsOutputDirectory
      Path.join(@fileOptions.outputDir, @fileOptions.outputName)
    else
      Path.join(Path.dirname(@fileOptions.path), @fileOptions.outputName)  # just a dummy path

    sourceAbsPath = @project.hive.absolutePathOf(@fileOptions.path)
    outputAbsPath = @project.hive.absolutePathOf(outputPath)

    LR.log.fyi "runCompiler for #{@fileOptions.path} into #{outputPath}, compiler #{@fileOptions.compiler.name}"

    info =
      "$(ruby)":         "/usr/bin/ruby"
      "$(node)":         process.argv[0]
      "$(plugin)":       @fileOptions.compiler.plugin.folder
      "$(project_dir)":  @project.hive.fullPath

      "$(src_path)":     sourceAbsPath
      "$(src_file)":     Path.basename(sourceAbsPath)
      "$(src_dir)":      Path.dirname(sourceAbsPath)
      "$(src_rel_path)": @fileOptions.path

      "$(dst_path)":     outputAbsPath
      "$(dst_file)":     Path.basename(outputAbsPath)
      "$(dst_dir)":      Path.dirname(outputAbsPath)
      "$(dst_rel_path)": outputPath

    info["$(additional)"] = []

    LR.log.fyi "Substituting info: #{JSON.stringify(info, null, 2)}"

    args = subst(@fileOptions.compiler.commandLine, info)
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
