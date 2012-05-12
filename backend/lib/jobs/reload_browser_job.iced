Job = require '../app/jobs'


class ReloadRequest

  constructor: (@project, @path, @originalPath) ->
    @requiresFullReload = !@path.match /\.(jpe?g|gif|png|css)$/


module.exports = class ReloadBrowserJob extends Job

  constructor: (@requests) ->
    super null

  merge: (sibling) ->
    @requests.pushAll sibling.requests

  execute: (callback) ->
    projects = @requests.map('project').unique('id')

    isFullReload = projects.any((p) -> p.disableLiveRefresh) || @requests.any((r) => r.requiresFullReload)

    fullPageReloadDelay = Math.min.apply(Math, projects.map('fullPageReloadDelay'))

    if isFullReload and fullPageReloadDelay > 0
      # TODO: we won't be running any other jobs while we're waiting here -- perhaps schedule a separate job instead?
      setTimeout @broadcastChangesToBrowser.bind(@, callback), fullPageReloadDelay
    else
      @broadcastChangesToBrowser(callback)

  broadcastChangesToBrowser: (callback) ->
    LR.stats.incr 'stat.reloads'
    for request in @requests
      LR.websockets.sendReloadCommand
        path:            request.path
        originalPath:    request.originalPath
        liveCSS:        !request.project.disableLiveRefresh
        enableOverride:  request.project.enableRemoteServerWorkflow
    callback(null)


ReloadBrowserJob.ReloadRequest = ReloadRequest
