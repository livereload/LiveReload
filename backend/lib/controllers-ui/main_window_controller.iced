
module.exports = class MainWindowController

  initialize: ->
    @$
      type: 'MainWindow'
      visible: true

      '#projectOutlineView':
        style: 'source-list'
        'dnd-drop-types': ['file']
        'dnd-drag': yes
        'cell-type': 'ImageAndTextCell'

      '#gettingStartedView':
        visible: no

    @updateProjectList()

  '#addProjectButton clicked': ->
    @setStatus "Add project clicked at #{Date.now()}"

  '#removeProjectButton clicked': ->
    @setStatus "Remove project clicked at #{Date.now()}"

  '#projectOutlineView selected': (arg) ->
    @setStatus "Selected: #{arg}"

  setStatus: (text) ->
    @$ '#statusTextField': text: text

  updateProjectList: ->
    listData =
      '#root':
        children: ['#folders']
      '#folders':
        label: "MONITORED FOLDERS"
        'is-group': yes
        children: ("#" + project.id for project in LR.model.workspace.projects)
        expanded: yes

    for project in LR.model.workspace.projects
      listData["#" + project.id] =
        label: project.name
        image: 'folder'
        expandable: no

    @$ '#projectOutlineView': data: listData
