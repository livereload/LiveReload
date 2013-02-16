{ EventEmitter } = require 'events'


merge = (dst, src) ->
  for own key, value of src
    if (key.match /^#/) and dst.hasOwnProperty(key) and value? and (oldValue = dst[key])? and (typeof value is 'object') and (typeof oldValue is 'object')
      merge oldValue, value
    else
      dst[key] = value
  dst


module.exports =
class UIConnector extends EventEmitter

  constructor: (@root, options={}) ->
    @_delay = options.delay ? 5

    @root.on 'update', @_mergeUpdate.bind(this)
    @_nextUpdatePayload = {}
    @_nextUpdateScheduled = no

  _mergeUpdate: (payload, callback) ->
    if callback
      @emit 'update', payload, callback
    else
      merge @_nextUpdatePayload, payload
      @_scheduleUpdate()
      # @emit 'update', payload

  _scheduleUpdate: ->
    return if @_nextUpdateScheduled
    @_nextUpdateScheduled = yes
    if @_delay is 0
      process.nextTick @_sendUpdate.bind(this)
    else
      setTimeout @_sendUpdate.bind(this), @_delay

  _sendUpdate: ->
    payload = @_nextUpdatePayload
    @_nextUpdatePayload = {}
    @_nextUpdateScheduled = no

    @emit 'update', payload
