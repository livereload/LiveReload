
module.exports = class MainWindowController

  initialize: ->
    @$
      type: 'MainWindow'
      visible: true

  '%projectList controller?': ->
    new (require './mainwindow_projectlist')(this)

  setStatus: (text) ->
    @$ '#statusTextField': text: text
