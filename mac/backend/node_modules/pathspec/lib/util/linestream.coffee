module.exports = (stream) ->
  result = new EventEmitter()
  leftover = ''

  stream.setEncoding 'utf-8'
  stream.on 'data', (chunk) ->
    lines = (leftover + chunk).split "\n"
    leftover = lines.pop()

    for line in lines
      result.emit 'line', line

    return

  stream.on 'end', ->
    if leftover
      result.emit 'line', leftover
    result.emit 'end'

  result
