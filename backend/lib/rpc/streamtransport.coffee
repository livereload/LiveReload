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
      LR.log.fyi "KTNXBYE"
      @emit 'end'

    @consoleDebuggingMode = no


  _processLine: (line) ->
    return if line == ''  # empty lines are handy when testing in console mode

    unless line.match /"app\.ping"/
      LR.log.fyi "App to Node: #{line}" unless @consoleDebuggingMode
    command = JSON.parse(line)
    @emit 'message', command


  send: (command) ->
    if typeof command[0] isnt 'string'
      throw new Error("Invalid type of message: #{command}")
    payload = JSON.stringify(command)
    buf = new Buffer("#{payload}\n")
    LR.log.fyi "Node to App: #{payload}" unless @consoleDebuggingMode
    @output.write "#{payload}\n"
