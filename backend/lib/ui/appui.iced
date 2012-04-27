
collectEventSelectorsInPayload = (payload) ->
  result = []
  for own k, v of payload
    if Object.isObject v
      for [child, arg] in collectEventSelectorsInPayload(v)
        result.push ["#{k} #{child}", arg]
    else
      result.push [k, v]
  return result

module.exports = class LRApplicationUI

  constructor: ->
    # @mainwnd = new (require './mainwnd')()

  start: (callback) ->
    # @mainwnd.show(callback)

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

    C.ui.update
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

  '#mainwindow #addProjectButton clicked': ->
    C.ui.update
      '#mainwindow':
        '#statusTextField':
          text: "Add project clicked at #{Date.now()}"

  '#mainwindow #removeProjectButton clicked': ->
    C.ui.update
      '#mainwindow':
        '#statusTextField':
          text: "Remove project clicked at #{Date.now()}"

  '#mainwindow #projectOutlineView selected': (arg) ->
    C.ui.update
      '#mainwindow':
        '#statusTextField':
          text: "Selected: #{arg}"

  notify: (payload) ->
    LR.log.fyi "Notification received: " + JSON.stringify(payload, null, 2)
    selectors = collectEventSelectorsInPayload(payload)
    LR.log.fyi "Selectors: " + JSON.stringify(selectors, null, 2)
    for [selector, arg] in selectors
      if func = @[selector]
        func.call(@, arg)
