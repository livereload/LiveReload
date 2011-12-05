{ EventEmitter }     = require 'events'
{ CommandProcessor } = require './command-processor'


class Communicator extends EventEmitter

  constructor: (@stdin, @stdout, @stderr) ->
    @stdin.resume()
    @stdin.setEncoding('utf8')

    @stdin.on 'data', (chunk) ->
      @stderr.write "Node received command: #{chunk}"
      [command, data] = JSON.parse(chunk)
      Commands[command].call(null, args)

    @stdin.on 'end', ->
      @emit 'end'

  send: (command, data, callback) ->
    payload = JSON.stringify([command, data])
    @stdout.write "#{payload}\n"
    callback(null)
