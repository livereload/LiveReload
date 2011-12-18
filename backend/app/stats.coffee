http = require 'http'


PREF_LANG_PING = 'stats.AppNewsKitLastPingTime'


Debug              = yes
PingInterval       = (24*60*60)
CheckInterval      = (30*60)
DebugPingInterval  = (60)
DebugCheckInterval = (10)


unixTime = -> Math.floor(+new Date() / 1000)


doPingServer = (scheduled) ->
  version = LR.version
  options =
    host: 'livereload.com'
    port: 80
    path: "/ping.php?platform=windows&v=#{version}&iv=#{version}&scheduled=#{scheduled && 1 || 0}"

  LR.log.fyi "Pinging server... (http://#{options.host}#{options.path})"

  http
    .get options, (res) ->
      LR.log.fyi "Server ping successful, response code = #{res.statusCode}"
      if res.statusCode is 200
        LR.preferences.set PREF_LANG_PING, unixTime()
    .on 'error', (err) ->
      LR.log.wtf "Server ping failed: #{err.message}"

pingServer = (force) ->
  LR.preferences.get PREF_LANG_PING, (value) ->
    schedule = value && unixTime() < value + PingInterval
    if Debug and value and (unixTime() < value + DebugPingInterval)
      force = yes
    if schedule or force
      doPingServer(schedule)


exports.startup = ->
  pingServer(yes)
  setTimeout (-> pingServer(no)), (Debug && DebugCheckInterval || CheckInterval)
