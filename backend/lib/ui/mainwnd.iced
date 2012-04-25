
{ UIWindow, UIButton } = require '../uilib/uilib'

module.exports = class LRMainWindowUI

  show: (callback) ->
    @window = new UIWindow 'MainWindow',
      addProjectButton: new UIButton
        click: =>
          LR.log.fyi "Clicked Add Project button"
      removeProjectButton: new UIButton
        click: =>
          LR.log.fyi "Clicked Remove Project button"

    await @window.create defer(err)
    await @window.show defer(err)

    callback(null)
