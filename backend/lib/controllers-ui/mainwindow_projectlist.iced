{ convertForestToBushes } = require '../util/bushes'

module.exports = class ProjectListController

  constructor: (@mainWindowController) ->
    @selectedProjectId = null

  initialize: ->
    @$
      '#projectOutlineView': {}

      '#gettingStartedView':
        visible: no

    # @_('#workspace #P6')

  '#addProjectButton clicked': ->
    @$ '$do': 'chooseFolderToAdd':
      callback: (folder) =>
        if folder
          LR.model.workspace.add { path: folder }, LR.consumeErr

  '#removeProjectButton clicked': ->
    if @selectedProjectId
      LR.model.workspace.remove { projectId: @selectedProjectId }, LR.consumeErr

  '#projectOutlineView selected': (arg) ->
    @selectedProjectId = arg && arg.substr(1)
    @mainWindowController.setStatus "Selected: #{arg}"
    if project = (arg && LR.model.workspace.findById(@selectedProjectId))
      @mainWindowController.detailPane.setProject project

  # '/workspace projectAdded': ->

  # '/workspace @selectedProjectId projectRemoved': ->

  render: ->
    @$ '#projectOutlineView': 'data': convertForestToBushes [
      id: '#folders'
      children:
        for project in LR.model.workspace.projects
          id:    "#" + project.id
          label: project.name
          tags:  '.project'
    ]
