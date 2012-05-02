{ convertForestToBushes } = require '../util/bushes'

module.exports = class ProjectListController

  constructor: (@model) ->
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
    if project = @model.selectedProject
      LR.model.workspace.remove { projectId: project.id }, LR.consumeErr

  '#projectOutlineView selected': (arg) ->
    if project = (arg && LR.model.workspace.findById(arg.substr(1)))
      LR.log.fyi "@model.statusText = #{@model.statusText}"
      @model.statusText = "Selected: #{arg}"
      @model.selectedProject = project

  render: ->
    @$ '#projectOutlineView': 'data': convertForestToBushes [
      id: '#folders'
      children:
        for project in LR.model.workspace.projects
          id:    "#" + project.id
          label: project.name
          tags:  '.project'
    ]
