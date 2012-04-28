
module.exports = class ProjectListController

  constructor: (@mainWindowController) ->

  initialize: ->
    @$
      '#projectOutlineView': {}

      '#gettingStartedView':
        visible: no

    @updateProjectList()

  '#addProjectButton clicked': ->
    @mainWindowController.setStatus "Add project clicked at #{Date.now()}"

  '#removeProjectButton clicked': ->
    @mainWindowController.setStatus "Remove project clicked at #{Date.now()}"

  '#projectOutlineView selected': (arg) ->
    @mainWindowController.setStatus "Selected: #{arg}"

  updateProjectList: ->
    listData =
      '#root':
        children: ['#folders']
      '#folders':
        children: ("#" + project.id for project in LR.model.workspace.projects)

    for project in LR.model.workspace.projects
      listData["#" + project.id] =
        label: project.name
        image: 'folder'
        expandable: no

    @$ '#projectOutlineView': 'data': listData
