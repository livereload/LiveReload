debug     = require('debug')('livereload:core:tools:cmdline')
subst     = require 'subst'
{ spawn } = require 'child_process'

Invocation = require './invocation'

module.exports =
class CommandLineTool

  constructor: ({ @name, @args, @cwd, @parser }) ->

  toString: ->
    "CommandLineTool(#{@name})"

  createInvocation: (info) ->
    new Invocation(this, info)

  invoke: (invocation, callback) ->
    args = subst(@args, invocation.info)
    cwd  = subst(@cwd,  invocation.info)

    debug "Invoking command line: #{JSON.stringify(args)}"

    command = args.shift()
    subprocess = spawn(command, args, cwd: cwd, env: process.env)

    stdout = []
    stderr = []
    subprocess.stdout.setEncoding 'utf8'
    subprocess.stderr.setEncoding 'utf8'
    subprocess.stdout.on 'data', (data) =>
      stdout.push data
    subprocess.stderr.on 'data', (data) =>
      stderr.push data

    await
      subprocess.on 'exit', defer(exitCode)
      subprocess.on 'close', defer()

    stdout = stdout.join('')
    stderr = stderr.join('')
    debug "Command outputs: " + JSON.stringify({ stdout, stderr, exitCode }, null, 2)

    parsed =
      stdout: @parser.parse(stdout)
      stderr: @parser.parse(stderr)

    messages = parsed.stdout.messages.concat(parsed.stderr.messages)

    if exitCode is 127
      messages.push { type: "error", message: "Invocation failed, cannot execute #{command}"}
    else if (exitCode isnt 0) and (messages.length is 0)
      messages.push { type: "error", message: "Non-zero exit code #{exitCode} returned by #{command}"}

    debug "Messages: " + JSON.stringify(messages, null, 2)
    invocation.messages = messages

    callback(null)
