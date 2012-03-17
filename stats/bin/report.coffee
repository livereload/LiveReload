require 'sugar'

fs    = require 'fs'
Path  = require 'path'
util  = require 'util'

{DataFileGroups} = require '../lib/datafiles'
filecrunching    = require '../lib/filecrunching'

options = require('dreamopt') [
  "Usage: node bin/report.js"

  "Generic options:"
]

die = (message) ->
  util.debug message
  process.exit 1


withTiming = (message, func) ->
  console.time message if message
  result = func()
  console.timeEnd message if message
  return result


loadViews = (viewsDir) ->
  jade = require 'jade'

  views = {}
  for fileName in fs.readdirSync(viewsDir) when fileName.endsWith('.jade')
    field    = fileName.replace /\.jade$/, ''
    filePath = Path.join(viewsDir, fileName)

    views[field] = jade.compile(fs.readFileSync(filePath, 'utf-8'), filename: filePath)

  return views


hashToArray = (hash, levels) ->
  if levels == 0
    return hash

  array = []

  for key in Object.keys(hash).sort()
    value = hash[key]
    value = hashToArray(value, levels - 1)

    value.key = key
    array.push value

  return array


temporalTransform = (lastN, periodsToData, levels) ->
  keys = (Object.keys(data) for own period, data of periodsToData).flatten().union().sort()
  periods = (period for own period, data of periodsToData).sort().last(lastN)

  result =
    cols:
      for period in periods
        {
          title: period
        }
    rows:
      for key in keys
        {
          key: key
          cols:
            for period in periods
              {
                # title: period
                value: periodsToData[period][key] || ''
              }
        }



loadData = (groupName, func) ->
  group = DataFileGroups[groupName]

  withTiming "load #{groupName}", ->
    periodsToData = {}
    for file in group.allFiles()
      periodsToData[file.id] = file.readSync()

    func(periodsToData, group.levels)


views = loadViews(Path.join(__dirname, '../views'))


segments = loadData('month-segments', temporalTransform.fill(5))


html = views.layout {
  title: "LiveReload Statistics"
  breadcrumbs: [
    { title: "LiveReload Statistics", active: yes }
  ]
  content: views.index({ segments })
}

DataFileGroups.html.mkdir()
fs.writeFileSync DataFileGroups.html.subpath('index.html'), html
