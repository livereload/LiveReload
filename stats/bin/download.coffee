require 'sugar'

fs    = require 'fs'
Path  = require 'path'
async = require 'async'
http  = require 'http'

fixupFuncs = require('../lib/fixups').defaultFuncs

outputDir = Path.join(__dirname, '../data/raw')
batchSize = 5000


downloadStats = (since, offset, callback) ->
  options = { host: 'livereload.com', port: 80, path: "/stats-export.php?since=#{since}&offset=#{offset}&limit=#{batchSize}"}
  console.log "\nLoading batch since #{since}, offset #{offset}, limit #{batchSize}...\n -> http://#{options.host}#{options.path}"
  http
    .get options, (res) ->
      res.setEncoding('utf8')
      data = []
      res.on 'data', (chunk) ->
        data.push chunk
      res.on 'end', ->
        stats = JSON.parse(data.join(''))
        callback null, { stats, hasMore: stats.length == batchSize }
    .on 'error', (err) ->
      callback(err)


writeDayStats = (day, stats, callback) ->
  for entry in stats
    for func in fixupFuncs
      func(entry)

  filePath = Path.join(outputDir, "#{day}.json")
  fs.writeFile filePath, JSON.stringify(stats, null, 2), callback
  console.log " -> #{day} saved (#{stats.length} stats)."


processStats = ({ date: prevLastDay, offset: prevOffset, stats: prevLastDayStats }, { stats, hasMore }, callback) ->
  statsByDay = stats.groupBy('date')
  days       = Object.keys(statsByDay).sort()
  console.log " -> Processing #{stats.length} loaded stats from #{days.first()} to #{days.last()}, plus #{prevLastDayStats.length} leftover stats from #{prevLastDay}."

  stats      = stats.concat(prevLastDayStats)
  statsByDay = stats.groupBy('date')
  days       = Object.keys(statsByDay).sort()

  if hasMore
    lastDay      = days.pop()
    lastDayStats = statsByDay[lastDay]
    nextMemento  = { date: lastDay, offset: lastDayStats.length, stats: lastDayStats }
  else
    nextMemento  = null

  async.series [
    (cb) -> async.forEach days, ((day, cb) -> writeDayStats(day, statsByDay[day], cb)), cb
    (cb) ->
      console.log " -> #{lastDay} postponed (#{lastDayStats.length} stats)." if lastDay
      cb(null)
  ], (err) -> callback(err, nextMemento)


processAll = (callback) ->
  existingDays = (day.replace('.json', '') for day in fs.readdirSync(outputDir) when day.match(/\.json$/)).sort()
  memento = { date: existingDays.last() || '2001-01-01', offset: 0, stats: [] }

  async.whilst (-> !!memento),
    async.waterfall.fill([
      (cb)              -> downloadStats(memento.date, memento.offset, cb)
      (stats, cb)       -> processStats(memento, stats, cb)
      (nextMemento, cb) -> memento = nextMemento; cb(null)
    ]),
    callback


processAll (err) ->
  throw err if err
  console.log "\nAll done."
