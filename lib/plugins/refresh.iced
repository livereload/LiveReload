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
    @queue.register { action: 'refresh' }, { idKeys: ['project', 'action'] }, @_perform.bind(@)

  schedule: (change) ->
    @queue.add { project: @project.id, action: 'refresh', change }
    debug "Scheduled browser refresh job for change: " + JSON.stringify(change)


  # internal

  _perform: (request, done) ->
    debug "Executing browser refresh job for change: " + JSON.stringify(request.change)
    # json_object_set_new(arg, "path", json_string(request->path));
    # json_object_set_new(arg, "originalPath", json_string(request->original_path ?: ""));
    # json_object_set_new(arg, "liveCSS", !project.disableLiveRefresh ? json_true() : json_false());
    # json_object_set_new(arg, "enableOverride", project.enableRemoteServerWorkflow ? json_true() : json_false());
    # _fullPageReloadDelay!!
    for path in request.change.paths
      command =
        command:        'reload'
        path:           path
        originalPath:   ''
        liveCSS:        !@project.disableLiveRefresh

        # enableOverride:  @project.enableRemoteWorkflow
        # if enableOverride and @urlOverrideCoordinator.shouldOverrideFile(path)
        #   message.overrideURL = @urlOverrideCoordinator.createOverrideURL(path)

      @session.sendBrowserCommand command

    done(null)
