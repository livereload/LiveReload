
DAY_FORMAT   = '{yyyy}-{MM}-{dd}'
MONTH_FORMAT = '{yyyy}-{MM}'
YEAR_FORMAT  = '{yyyy}'

DAY_REGEXP   = /^((\d{4})-\d{2})-\d{2}$/
MONTH_REGEXP = /^(\d{4})-\d{2}$/


N = (g) ->
  if typeof g is 'string'
    g
  else
    g.name

METHODS = ['first', 'last', 'outer']


class Granularity

  constructor: (@name) ->
    for method in METHODS
      @[method + @name] = (period) -> period

  compare: (a, b) ->
    a.compare(b)

  lt: (a, b) -> @compare(a, b) <  0
  le: (a, b) -> @compare(a, b) <= 0
  gt: (a, b) -> @compare(a, b) >  0
  ge: (a, b) -> @compare(a, b) >= 0
  eq: (a, b) -> @compare(a, b) == 0
  ne: (a, b) -> @compare(a, b) != 0

  for method in METHODS
    do (method) =>
      @::[method] = (granularity, period) -> this[method + N(granularity)].call(this, period)

  @define: (granularity) ->
    for method in METHODS
      do (method) =>
        @::[method + granularity] = (period) -> throw new Error("Unsupported G.#{@name}.#{method}(#{granularity}, #{period})")

  startTime: (period) ->
  endTime:   (period) -> Date.create(@lastday(period)).setUTC().endOfDay()

  wrap: (period) -> new Period(this, period)


module.exports = G =
  day:
    Object.merge new Granularity('day'),
      outermonth: (period) -> period.replace(DAY_REGEXP, '$1')
      outeryear:  (period) -> period.replace(DAY_REGEXP, '$2')

  week:
    Object.merge new Granularity('week'), {}

  month:
    Object.merge new Granularity('month'),
      firstday:  (period) -> period + '-01'
      lastday:   (period) -> Date.create(period).endOfMonth().format()
      outeryear: (period) -> period.replace(MONTH_REGEXP, '$1')

  year:
    Object.merge new Granularity('year'),
      firstday:   (period) -> period + '-01-01'
      firstmonth: (period) -> period + '-01'
      lastday:    (period) -> period + '-12-' + Date.create(period + '-12').daysInMonth()
      lastmonth:  (period) -> period + '-12'

do ->
  G.all = (k for own k of G)
  G.allObjects = (v for own k, v of G)
  for g in G.all
    Granularity.define g




class Period
  constructor: (@granularity, @string) ->

  toString: -> @string

  startTime: -> @_startTime ||= Date.create(@firstday()).setUTC().beginningOfDay()
  endTime:   -> @_endTime   ||= Date.create(@lastday()) .setUTC().endOfDay()

  startUnixTime: -> @_startUnixTime ||= Math.round(@startTime().getTime() / 1000)
  endUnixTime:   -> @_endUnixTime   ||= Math.round(@endTime()  .getTime() / 1000)

  for method in METHODS
    for granularity in G.allObjects
      methodName = method + granularity.name
      @::[methodName] = do (methodName) ->
        varName = '_' + methodName
        -> @[varName] ||= @granularity[methodName].call(@granularity, @string)
