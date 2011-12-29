Hierarchy        = require '../hierarchy'
rawentries       = require '../rawentries'

module.exports = (day, stats) ->
  usersToEventsToData = Hierarchy()
  for entry in stats
    userId = rawentries.guessUserId(entry)
    usersToEventsToData.add userId, rawentries.computeEvents(entry)
  return usersToEventsToData
