
module.exports = class LRMainWindowUI

  show: (callback) ->
    await C.ui.createWindow { class: "MainWindow" }, defer(err, @window)
    await C.ui.showWindow { window: @window }, defer(err)
    callback(null)
