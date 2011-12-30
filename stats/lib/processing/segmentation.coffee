Hierarchy   = require '../hierarchy'
{EventType} = require '../eventtypes'


computeSegments = (userData) ->
  segmentNames = ["g:all", "g:status:#{userData.status}", "g:engagement:#{userData.engagement}", "g:knownfor:#{userData.knownfor}"]

  segmentData = EventType.segment.map(userData)

  segmentsToData = Hierarchy()
  for name in segmentNames
    segmentsToData[name] = segmentData
  return segmentsToData


module.exports = (period, usersToData) ->
  segmentsToData = Hierarchy()

  for own userId, userData of usersToData
    segmentsToData.merge computeSegments(userData)

  return segmentsToData
