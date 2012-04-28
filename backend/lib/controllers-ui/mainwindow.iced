
module.exports = class MainWindowController

  initialize: ->
    @$
      type: 'MainWindow'
      visible: true

  '%projectList controller?': ->
    new (require './mainwindow_projectlist')(this)

  '%detailPane controller?': ->
    @detailPane = new (require './mainwindow_detailpane')(this)

  setStatus: (text) ->
    @$ '#statusTextField': text: text
