R = require '../reactive'

class MainWindow extends R.Entity

  constructor: ->
    super()

    @__defprop 'selectedProject', null
    @__defprop 'statusText', 'Hello'

    @__deriveprop 'visiblePane', =>
      switch
        when @selectedProject then 'details'
        else 'welcome'

module.exports = class MainWindowController

  constructor: ->
    @model = new MainWindow()

  initialize: ->
    @$ visible: true

    LR.queue.on 'running', =>
      @model.statusText = "Running #{LR.queue.runningJob}..."

    LR.queue.on 'empty', =>
      @model.statusText = "All jobs finished."

  render: ->
    @$ '#statusTextField': text: @model.statusText

    @$ '#welcomePane': visible: (@model.visiblePane is 'welcome')
    @$ '#projectPane': visible: (@model.visiblePane is 'details')

  '%projectList controller?': ->
    new (require './mainwindow_projectlist')(@model)

  '%detailPane controller?': ->
    @detailPane = new (require './mainwindow_detailpane')(@model)
