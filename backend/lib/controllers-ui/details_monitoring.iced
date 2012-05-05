R = require '../reactive'

module.exports = class MonitoringOptionsController

  constructor: (@project) ->
    @id = '#monitoring'

  initialize: ->
    @$
      'parent-window': '#mainwindow'
      'parent-style': 'sheet'
      visible: yes

  '#applyButton clicked': ->
    @$ visible: no

  render: ->
    # @$ '#statusTextField': text: @model.statusText

    # @$ '#welcomePane': visible: (@model.visiblePane is 'welcome')
    # @$ '#projectPane': visible: (@model.visiblePane is 'details')
