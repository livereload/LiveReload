
EventType =
  single:
    map: ({ time }) -> { first: time, last: time, count: 1 }

    clone: ({ first, last, count }) -> { first, last, count }

    reduce: (a, b) ->
      a.first  = Math.min(a.first, b.first)
      a.last   = Math.max(a.last, b.last)
      a.count += b.count

  aggregate:
    map: ({ first, last, count }) -> { first, last, mincount: count, maxcount: count }

    clone: ({ first, last, mincount, maxcount }) -> { first, last, mincount, maxcount }

    reduce: (a, b) ->
      a.first    = Math.min(a.first, b.first)
      a.last     = Math.max(a.last, b.last)
      a.mincount = Math.min(a.mincount, b.mincount)
      a.maxcount = Math.max(a.maxcount, b.maxcount)


EventType.prefixes = prefixes =
  e: EventType.single
  v: EventType.single
  s: EventType.aggregate


reportMalformedEventName = (event) -> throw new Error("Event #{event} does not have a valid type prefix")

EventType.of = (event) ->
  (event.length > 2) && (event[1] == ':') && prefixes[event[0]] || reportMalformedEventName(event)


exports.EventType = EventType
