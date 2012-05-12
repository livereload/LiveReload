log = require('dreamlog')('livereload.rpc')

{ EventEmitter } = require 'events'

module.exports = class LineOrientedStreamTransport extends EventEmitter

  # kind of like Pascal :-)
  constructor: (@input, @output) ->
    @input.resume()
    @input.setEncoding('utf8')
    @buffer = ""

    @input.on 'data', (chunk) =>
      [lines..., @buffer] = (@buffer + chunk).split("\n")
      for line in lines
        @_processLine line

    @input.on 'end', =>
      log.fyi "KTNXBYE"
      @emit 'end'


  _processLine: (line) ->
    return if line == ''  # empty lines are handy when testing in console mode

    unless line.match /"app\.ping"/
      log.fyi "App to Node: {line}", { line }
    command = JSON.parse(line)
    @emit 'message', command


  send: (command) ->
    if typeof command[0] isnt 'string'
      throw new Error("Invalid type of message: #{command}")
    payload = JSON.stringify(command)
    buf = new Buffer("#{payload}\n")
    log.fyi "Node to App: {payload}", { payload }
    @output.write "#{payload}\n"
