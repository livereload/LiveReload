Hierarchy        = require '../hierarchy'

module.exports = (period, srcitems) ->
  usersToEventsToData = Hierarchy()
  for { srcperiod, stats } in srcitems
    usersToEventsToData.merge stats
  return usersToEventsToData
