
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
    listData =
      '#root':
        children: ['#folders']
      '#folders':
        children: ("#" + project.id for project in LR.model.workspace.projects)

    for project in LR.model.workspace.projects
      listData["#" + project.id] =
        label: project.name
        tags: '.project'

    @$ '#projectOutlineView': 'data': listData
