Hierarchy = require '../hierarchy'


TRIAL_PERIOD      =  7
INACTIVITY_CUTOFF = 14

DAY = (1).day() / 1000


analyzeUser = (period, eventsToData) ->
  pingEventData = eventsToData['e:ping']

  firstPingTime      = pingEventData.first
  lastPingTime       = pingEventData.last
  activityDuration   = ((lastPingTime - firstPingTime) / DAY).round(1)
  inactivityDuration = ((period.endUnixTime() - lastPingTime) / DAY).round(1)
  age                = ((period.endUnixTime() - firstPingTime) / DAY).round(1)

  if age < TRIAL_PERIOD
    engagement = 'trial'
  else if inactivityDuration > INACTIVITY_CUTOFF || inactivityDuration > activityDuration
    engagement = 'inactive'
  else
    engagement = 'active'

  return { firstPingTime, lastPingTime, activityDuration, inactivityDuration, age, engagement }


module.exports = (period, usersToEventsToData) ->
  usersToData = Hierarchy()
  require('util').debug "usersToEventsToData keys: #{Object.keys(usersToEventsToData).length}"
  for own userId, eventsToData of usersToEventsToData
    usersToData.add userId, analyzeUser(period, eventsToData)
  require('util').debug "output keys: #{Object.keys(usersToData).length}"
  return usersToData
