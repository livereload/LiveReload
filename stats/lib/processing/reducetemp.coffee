Hierarchy        = require '../hierarchy'

module.exports = (period, current, prevPeriod, prev) ->
  # require('util').debug "cur pings = #{current['93.92.217.130']['e:ping'].count}"
  if prev
    # require('util').debug "prev pings = #{prev['93.92.217.130']['e:ping'].count}"
    usersToEventsToData = Hierarchy()
    usersToEventsToData.merge prev
    usersToEventsToData.merge current
    # require('util').debug "sum pings = #{usersToEventsToData['93.92.217.130']['e:ping'].count}"
    return usersToEventsToData
  else
    return current
module.exports.temporalOutput = yes
