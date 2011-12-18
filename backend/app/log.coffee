
exports.omg = (message) ->
  process.stderr.write "node OMG: #{message.trim()}\n"

exports.wtf = (message) ->
  process.stderr.write "node WTF: #{message.trim()}\n"

exports.fyi = (message) ->
  process.stderr.write "node: #{message.trim()}\n"
