
class LRConsole

  constructor: ->
    @lines = []
    @capacity = 10000

  puts: (line) ->
    @lines.push.apply @lines, line.split("\n")
    @_trim()
    undefined

  _trim: ->
    if (extra = @lines.length - @capacity) > 0
      @lines.splice 0, extra

module.exports = LRConsole
