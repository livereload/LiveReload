{EventType}      = require './eventtypes'
Hierarchy        = require '../lib/hierarchy'


exports.guessUserId = (entry) -> 'u:' + entry.ip


guessOperatingSystem = (agent) ->
  switch
    when !agent                       then 'unknown'
    when agent.match(/Darwin\/11\.2/) then 'mac_10_7'
    when agent.match(/Darwin\/10\.8/) then 'mac_10_6'
    else                                   'unknown'


exports.computeEvents = (entry) ->
  events = ['e:ping']
  events.push "v:version:#{entry.iversion}"  if entry.iversion
  events.push "v:platform:mac"
  events.push "v:os:" + guessOperatingSystem(entry.agent)

  eventsToData = Hierarchy()

  eventData = EventType.single.map(entry)
  for event in events
    eventsToData[event] = eventData

  if stats = entry.stats
    keys = (key.replace(/_(first|last)$/, '') for key in Object.keys(stats)).unique()
    for key in keys
      count = stats[key]
      first = stats[key + '_first']
      last  = stats[key + '_last']

      if count? and first? and last?
        eventsToData['s:' + key] = EventType.aggregate.map({ first, last, count })

  return eventsToData
