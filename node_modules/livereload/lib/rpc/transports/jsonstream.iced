debug = require('debug')('livereload:rpc')

{ EventEmitter } = require 'events'

module.exports =
class JSONStreamTransport extends EventEmitter

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
      debug "KTNXBYE"
      @emit 'end'


  _processLine: (line) ->
    return if line == ''  # empty lines are handy when testing in console mode

    unless line.match /"app\.ping"/
      debug "App to Node: %s", line
    command = JSON.parse(line)
    @emit 'message', command


  send: (command) ->
    if typeof command[0] isnt 'string'
      throw new Error("Invalid type of message: #{command}")
    payload = JSON.stringify(command)
    buf = new Buffer("#{payload}\n")
    debug "Node to App: %s", payload
    @output.write "#{payload}\n"
