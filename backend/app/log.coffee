
exports.omg = (message) ->
  process.stderr.write "node error: #{message.trim()}\n"

exports.wtf = (message) ->
  process.stderr.write "node warning: #{message.trim()}\n"

exports.fyi = (message) ->
  process.stderr.write "node fyi: #{message.trim()}\n"
