

module.exports = class ApplicationController

  initialize: ->
    # @$ '#mainwindow': yes

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

    @$
      '#mainwindow':
        type: 'MainWindow'
        visible: true

        '#addProjectButton': {}
        '#removeProjectButton': {}

        '#projectOutlineView':
          style: 'source-list'
          'dnd-drop-types': ['file']
          'dnd-drag': yes
          'cell-type': 'ImageAndTextCell'
          data: listData

        '#gettingStartedView':
          visible: no

  '#mainwindow controller?': ->
    new (require './main_window_controller')

  '#mainwindow #addProjectButton clicked': ->
    @$ '#mainwindow': '#statusTextField': text: "Add project clicked at #{Date.now()}"

  '#mainwindow #removeProjectButton clicked': ->
    @$ '#mainwindow': '#statusTextField': text: "Remove project clicked at #{Date.now()}"

  '#mainwindow #projectOutlineView selected': (arg) ->
    @$ '#mainwindow': '#statusTextField': text: "Selected: #{arg}"

