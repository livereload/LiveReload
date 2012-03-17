Hierarchy = require '../hierarchy'


TRIAL_PERIOD      = 7
INACTIVITY_CUTOFF = 14


# return { firstPingTime, lastPingTime, activityDuration, inactivityDuration, age, engagement }
NULL_PREV =
  engagement:          'none'
  hasEverBeenActive:   no
  hasEverBeenInTrial:  no
  engagementStats:     {}
  statusStats:         {}
  statusHistory:       []
  knownfor:            0


appendToHistory = (history, item) ->
  history = history.slice(0)

  if (last = history.last()) and (last[0] == item)
    history[history.length - 1] = [item, last[1] + 1]
  else
    history.push [item, 1]
  return history


analyzeUser = (period, userData, prevUserData=NULL_PREV) ->
  userData = Object.clone(userData, true)

  userData.hasEverBeenInTrial = (userData.engagement is 'trial')  || prevUserData.hasEverBeenInTrial
  userData.hasEverBeenActive  = (userData.engagement is 'active') || prevUserData.hasEverBeenActive

  userData.status =
    if userData.engagement == prevUserData.engagement
      userData.engagement
    else if userData.engagement is 'active'
      if prevUserData.hasEverBeenActive
        'returning'
      else
        'new'
    else if userData.engagement is 'inactive'
      if prevUserData.engagement is 'active'
        'gone'
      else
        'bounced'
    else
      userData.engagement

  userData.engagementStats = prevUserData.engagementStats
  userData.statusStats = prevUserData.statusStats

  userData.engagementStats[userData.engagement] = (userData.engagementStats[userData.engagement] || 0) + 1
  userData.statusStats[userData.status] = (userData.statusStats[userData.status] || 0) + 1

  userData.statusHistory = appendToHistory(prevUserData.statusHistory, userData.status)

  userData.knownfor = prevUserData.knownfor + 1

  return userData


module.exports = (period, usersToData, prevPeriod, prevUsersToData={}) ->
  newUsersToData = Hierarchy()

  for own userId, userData of usersToData
    newUsersToData.add userId, analyzeUser(period, userData, prevUsersToData[userId])

  return newUsersToData

module.exports.temporalOutput = yes
