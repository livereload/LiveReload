
module.exports = class LRApplicationUI

  constructor: ->
    # @mainwnd = new (require './mainwnd')()

  start: (callback) ->
    # @mainwnd.show(callback)
    C.ui.update
      '#mainwindow':
        type: 'MainWindow'
        visible: true

        '#addProjectButton': {}

    visible = yes
    setInterval =>
      visible = !visible
      C.ui.update
        '#mainwindow':
          visible: visible
    , 2000
    callback(null)

  notify: (payload) ->
    LR.log.fyi "Notification received: " + JSON.stringify(payload, null, 2)
