debug = require('debug')('livereload:core:refresh')

module.exports =
class RefreshPlugin

  metadata:
    apiVersion: 1
    name: 'livereload-refresh'

  jobPriorities: [
    'refresh'
  ]

  loadProject: (project, memento) ->
    # project.postprocCommand = (memento?.postproc ? '').trim()

  createSteps: (project) ->
    [new RefreshStep(project)]


class RefreshStep

  constructor: (@project) ->
    @id = 'refresh'
    @session = @project.session
    @queue   = @session.queue


  # LiveReload API

  initialize: () ->
    @queue.register { project: @project.id, action: 'refresh' }, @_perform.bind(@)

  schedule: (change) ->
    @queue.add { project: @project.id, action: 'refresh', paths: change.pathsToRefresh.slice(0) }
    debug "Scheduled browser refresh job for change: " + JSON.stringify(change)


  # internal

  _perform: (request, done) ->
    debug "Executing browser refresh job: " + JSON.stringify(request)
    return done(null) if request.paths.length == 0

    # json_object_set_new(arg, "path", json_string(request->path));
    # json_object_set_new(arg, "originalPath", json_string(request->original_path ?: ""));
    # json_object_set_new(arg, "liveCSS", !project.disableLiveRefresh ? json_true() : json_false());
    # json_object_set_new(arg, "enableOverride", project.enableRemoteServerWorkflow ? json_true() : json_false());
    # _fullPageReloadDelay!!
    action = { id: 'refresh', message: "Refreshing browser" }
    @project.reportActionStart(action)
    for path in request.paths
      command =
        command:        'reload'
        path:           path
        originalPath:   ''
        liveCSS:        !@project.disableLiveRefresh

        # enableOverride:  @project.enableRemoteWorkflow
        # if enableOverride and @urlOverrideCoordinator.shouldOverrideFile(path)
        #   message.overrideURL = @urlOverrideCoordinator.createOverrideURL(path)

      @session.sendBrowserCommand command
    @project.reportActionFinish(action)

    done(null)
