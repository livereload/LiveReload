debug = require('debug')('livereload:stats')
http = require 'http'


PREF_LANG_PING = 'stats.AppNewsKitLastPingTime'


Debug              = no
PingInterval       = (24*60*60)
CheckInterval      = (30*60)
DebugPingInterval  = (60)
DebugCheckInterval = (10)


unixTime = -> Math.floor(+new Date() / 1000)


module.exports =
class LRStats
  constructor: (@preferences) ->

  doPingServer: (scheduled) ->
    version = LR.version
    options =
      host: 'ping.livereload.com'
      port: 80
      path: "/news.json?apiver=1&platform=windows&v=#{version}&iv=#{version}&scheduled=#{scheduled && 1 || 0}"

    debug "Pinging server... (http://#{options.host}#{options.path})"

    http
      .get options, (res) =>
        debug "Server ping successful, response code = #{res.statusCode}"
        if res.statusCode is 200
          @preferences.set PREF_LANG_PING, unixTime()
      .on 'error', (err) =>
        debug "ERROR: Server ping failed: #{err.message}"

  pingServer: (force) ->
    @preferences.get PREF_LANG_PING, (value) =>
      schedule = value && unixTime() > value + PingInterval
      if Debug and value and (unixTime() > value + DebugPingInterval)
        force = yes
      if schedule or force
        @doPingServer(schedule)


  startup: ->
    @pingServer(yes)
    setInterval (=> @pingServer(no)), (Debug && DebugCheckInterval || CheckInterval) * 1000
