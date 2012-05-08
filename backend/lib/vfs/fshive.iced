{ EventEmitter } = require 'events'

Path = require 'path'

abspath = (path) ->
  if path.charAt(0) is '~'
    home = process.env.HOME
    if path.length is 1
      home
    else if path.charAt(1) is '/'
      Path.resolve(home, path.substr(2))
    else if m = path.match ///^ ~ ([^/]+) / (.*) $ ///
      other = Path.join(Path.dirname(home), m[1])  # TODO: resolve other users' home folders properly
      Path.resolve(other, m[2])
  else
    Path.resolve(path)

# there's got to be a better name for this...
class FSHive extends EventEmitter

  constructor: (@id, @path) ->
    @_disposed = no
    @_monitoring = no
    @_monitoringRequests = {}

    @fullPath = abspath(@path)

  dispose: ->
    unless @_disposed
      @_disposed = yes
      @_stopMonitoring() if @_monitoring
      @emit 'dispose'

  requestMonitoring: (key, state) ->
    if state
      unless key of @_monitoringRequests
        @_monitoringRequests[key] = yes
        @_updateMonitoringState()
    else
      if key of @_monitoringRequests
        delete @_monitoringRequests[key]
        @_updateMonitoringState()

  _updateMonitoringState: ->
    shouldMonitor = Object.keys(@_monitoringRequests).length > 0
    if shouldMonitor != @_monitoring
      if shouldMonitor
        @_startMonitoring()
      else
        @_stopMonitoring()

  _startMonitoring: ->
    LR.client.monitoring.add { id: @id, path: @fullPath }
    @_monitoring = yes

  _stopMonitoring: ->
    LR.client.monitoring.remove { id: @id }
    @_monitoring = no

  handleFSChangeEvent: (event, callback) ->
    if event.changes
      @emit 'change', event.changes, callback
    else
      @emit 'tree', event.tree, callback

  absolutePathOf: (relativePath) ->
    Path.join(@fullPath, relativePath)

module.exports = FSHive
