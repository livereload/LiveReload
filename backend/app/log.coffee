
fill = (n) ->
  if 0 < n < 10
    "0#{n}"
  else
    "#{n}"

now = ->
  date = new Date()
  y = date.getFullYear()
  m = fill(1 + date.getMonth())
  d = fill(date.getDate())
  H = fill(date.getHours())
  M = fill(date.getMinutes())
  S = fill(date.getSeconds())
  "#{y}-#{m}-#{d} #{H}:#{M}:#{S}"


exports.omg = (message) ->
  process.stderr.write "#{now()} node OMG: #{message.trim()}\n"

exports.wtf = (message) ->
  process.stderr.write "#{now()} node WTF: #{message.trim()}\n"

exports.fyi = (message) ->
  process.stderr.write "#{now()} node: #{message.trim()}\n"
