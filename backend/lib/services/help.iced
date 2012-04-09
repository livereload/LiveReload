
class LRHelp

  displayCriticalError: ({title, text, url, button}) ->
    button ?= "More Info"

    LR.log.omg "#{title} -- #{text}"
    LR.client.app.displayPopupMessage {
        title, text, buttons: [['help', button], ['quit', "Quit"]]
      }, (err, result) ->
        if result == 'help'
          LR.client.app.openUrl url
        LR.client.app.terminate()

  displayHelpfulWarning: ({title, text, url, button}) ->
    button ?= "More Info"

    LR.log.wtf "#{title} -- #{text}"
    LR.client.app.displayPopupMessage {
        title, text, buttons: [['help', button], ['ignore', "Ignore"]]
      }, (err, result) ->
        if result == 'help'
          LR.client.app.openUrl url


module.exports = LRHelp
