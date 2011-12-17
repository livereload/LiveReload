fs = require 'fs'
{ EventEmitter }     = require 'events'


class exports.Communicator extends EventEmitter

  constructor: (@stdin, @stdout, @stderr, @execute) ->
    @stdin.resume()
    @stdin.setEncoding('utf8')
    @commandsInFlight = 0
    @buffer = ""

    @stdin.on 'data', (chunk) =>
      [lines..., @buffer] = (@buffer + chunk).split("\n")
      for line in lines
        @processLine line

    @stdin.on 'end', =>
        process.stderr.write "stdin EOF.\n"
      @emit 'end'

  processLine: (line) ->
    @stderr.write "Node received command: #{line}\n"
    command = JSON.parse(line)
    @processCommand command, (err) ->
      process.stderr.write "command processed, err = #{err}.\n"
      throw err if err

  processCommand: (command, callback) ->
    @beforeCommand()

    @execute command, (err, reply) =>
      if err
        @afterCommand()
        return callback(err)
      if reply
        @send reply, (err) =>
          @afterCommand()
          return callback(err)
      return callback(null)

  beforeCommand: ->
    ++@commandsInFlight

  afterCommand: ->
    --@commandsInFlight
    if @commandsInFlight is 0
      @emit 'idle'

  send: (command) ->
    payload = JSON.stringify(command)
    buf = new Buffer("#{payload}\n")
    process.stderr.write "Node sending: #{payload}\n"
    @stdout.write "#{payload}\n"
