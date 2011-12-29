Hierarchy        = require '../hierarchy'

module.exports = (dstperiod, srcitems) ->
  usersToEventsToData = Hierarchy()
  for { period, stats } in srcitems
    usersToEventsToData.merge stats
  return usersToEventsToData
