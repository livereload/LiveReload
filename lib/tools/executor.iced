debug = require('debug')('livereload:core:executor')

module.exports = execute = ({ commandLine, info, cwd }) ->

  args = subst(commandLine, info)
  # LR.log.fyi "Invoking command line: #{JSON.stringify(args)}"

  command = args.shift()
  subprocess = spawn(command, args, cwd, env: process.env)

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
