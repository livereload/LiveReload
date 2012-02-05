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
      LR.log.fyi "KTNXBYE"
      @emit 'end'

  processLine: (line) ->
    return if line == ''  # empty lines are handy when testing in console mode

    unless line.match /"app\.ping"/
      LR.log.fyi "App to Node: #{line}"
    command = JSON.parse(line)
    @processCommand command, (err) ->
      if err
        LR.log.omg "Error encountered while processing incoming command: #{err.message}. Will die."
      throw err if err

  processCommand: (command, callback) ->
    @beforeCommand()

    @execute command, (err, reply) =>
      @afterCommand()
      return callback(err)

  beforeCommand: ->
    ++@commandsInFlight

  afterCommand: ->
    --@commandsInFlight
    if @commandsInFlight is 0
      @emit 'idle'

  send: (command) ->
    if typeof command[0] isnt 'string'
      throw new Error("Invalid type of message: #{command}")
    payload = JSON.stringify(command)
    buf = new Buffer("#{payload}\n")
    LR.log.fyi "Node to App: #{payload}"
    @stdout.write "#{payload}\n"
