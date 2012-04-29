{ convertForeshToBushes } = require '../util/bushes'

module.exports = class ProjectListController

  constructor: (@mainWindowController) ->

  initialize: ->
    @$
      '#projectOutlineView': {}

      '#gettingStartedView':
        visible: no

    @updateProjectList()

  '#addProjectButton clicked': ->
    @$ '$do': 'chooseFolderToAdd':
      callback: (folder) =>
        @mainWindowController.setStatus "Add project: #{folder}"

  '#removeProjectButton clicked': ->
    @mainWindowController.setStatus "Remove project clicked at #{Date.now()}"

  '#projectOutlineView selected': (arg) ->
    @mainWindowController.setStatus "Selected: #{arg}"
    if project = arg && LR.model.workspace.findById(arg.substr(1))
      @mainWindowController.detailPane.setProject project

  updateProjectList: ->
    @$ '#projectOutlineView': 'data': convertForeshToBushes [
      id: '#folders'
      children:
        for project in LR.model.workspace.projects
          id:    "#" + project.id
          label: project.name
          tags:  '.project'
    ]
