exports.parseStats = (entry) ->
  if typeof(entry.stats) is 'string'
    if entry.stats == ''
      entry.stats = {}
      return { isModified: yes, empty: 1 }
    else
      entry.stats = JSON.parse(entry.stats)
      return { isModified: yes, nonEmpty: 1 }
  else
    return null

exports.force = (entry) ->
  return { isModified: yes }

exports.dummy = (entry) ->
  null


for name, func of exports
  func.name = name

exports.default = ['parseStats']
exports.defaultFuncs = (exports[name] for name in exports.default)
