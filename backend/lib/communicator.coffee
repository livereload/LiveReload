fs = require 'fs'
{ EventEmitter }     = require 'events'


class exports.Communicator extends EventEmitter

  constructor: (@stdin, @stdout, @stderr, @execute) ->
    @stdin.resume()
    @stdin.setEncoding('utf8')
    @commandsInFlight = 0

    @stdin.on 'data', (chunk) =>
      @stderr.write "Node received command: #{chunk}"
      [command, args...] = JSON.parse(chunk)
      @processCommand command, args, (err) ->
        process.stderr.write "command processed, err = #{err}.\n"
        throw err if err

    @stdin.on 'end', =>
        process.stderr.write "stdin EOF.\n"
      @emit 'end'

  processCommand: (command, args, callback) ->
    @beforeCommand()

    @execute command, args..., (err, reply) =>
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

  send: (command, args...) ->
    payload = JSON.stringify([command, args...])
    buf = new Buffer("#{payload}\n")
    process.stderr.write "Node sending: #{payload}\n"
    @stdout.write "#{payload}\n"
