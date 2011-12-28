require 'sugar'

fs    = require 'fs'
Path  = require 'path'
async = require 'async'
http  = require 'http'

outputDir = Path.join(__dirname, '../data/raw')


merge = (totals, current) ->
  for own k, v of current
    if k of totals
      switch typeof v
        when 'object'
          merge totals[k], v
        when 'boolean'
          totals[k] ||= v
        when 'number'
          totals[k] += v
        else
          throw new Error("Unsupported type for merging: #{typeof(v)}")
    else
      totals[k] = v


processEntry = (entry, fixups) ->
  entryStats = { entries: 1 }

  for fixup in fixups
    fixupStats = fixup(entry) || {}

    fixupStats[fixupStats.isModified && 'applied' || 'skipped'] = 1
    delete fixupStats.isModified

    stats = { isModified: !!fixupStats.applied }
    stats[fixup.name] = fixupStats
    merge entryStats, stats

  return entryStats


processDay = (entries, fixups) ->
  dayStats = { days: 1 }

  for entry in entries
    entryStats = processEntry(entry, fixups)

    entryStats[entryStats.isModified && 'modified' || 'unmodified'] = 1
    delete entryStats.isModified

    merge dayStats, entryStats

  return dayStats


processAll = (fixups) ->
  console.log "Applying #{fixups.join(', ')}..."

  overallStats = {}

  for fileName in fs.readdirSync(outputDir) when fileName.match(/\.json$/)
    filePath = Path.join(outputDir, fileName)

    console.log " -> #{fileName}"
    entries = JSON.parse(fs.readFileSync(filePath, 'utf8'))

    dayStats = processDay(entries, fixups)

    if dayStats.modified > 0
      console.log "    #{JSON.stringify(dayStats)}"
      fs.writeFileSync filePath, JSON.stringify(entries, null, 2)

    dayStats[(dayStats.modified > 0) && 'modifiedDays' || 'unmodifiedDays'] = 1
    merge overallStats, dayStats

  console.log "\nDone applying #{fixups.join(', ')}. #{JSON.stringify(overallStats)}"


fixupNotFound = (name) ->
  console.log "Fixup not found: #{name}"
  process.exit 1

run = ->
  names  = process.argv.slice(2)

  Fixups = require '../lib/fixups'
  fixups = names.map((name) -> Fixups[name] || fixupNotFound(name))

  processAll(fixups)


run()
