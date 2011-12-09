fs = require 'fs'
{ EventEmitter }     = require 'events'
{ CommandProcessor } = require './command-processor'


class exports.Communicator extends EventEmitter

  constructor: (@stdin, @stdout, @stderr) ->
    @stdin.resume()
    @stdin.setEncoding('utf8')
    @commandsInFlight = 0

    @processor = new CommandProcessor (args...) =>
      @send(args...)

    @stdin.on 'data', (chunk) =>
      @stderr.write "Node received command: #{chunk}"
      [command, data] = JSON.parse(chunk)
      @processCommand command, data, (err) ->
        process.stderr.write "command processed, err = #{err}.\n"
        throw err if err

    @stdin.on 'end', =>
        process.stderr.write "stdin EOF.\n"
      @emit 'end'

  processCommand: (command, data, callback) ->
    @beforeCommand()

    @processor[command].call @processor, data, (err, reply) =>
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

  send: (command, callback) ->
    payload = JSON.stringify(command)
    buf = new Buffer("#{payload}\n")
    process.stderr.write "Node sending: #{payload}\n"
    @stdout.write "#{payload}\n"
    callback(null)
