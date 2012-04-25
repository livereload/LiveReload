
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

  openSupportTicket: (subject, body, callback) ->
    body = "#{body}\n\nI'm using LiveReload v#{LR.version}-#{LR.platform}.\n\nRemember: please attach the log file from `#{LR.logDir}`!"

    subject = encodeURIComponent(subject)
    body    = encodeURIComponent(body)

    C.app.openUrl "http://help.livereload.com/discussion/new?discussion%%5Btitle%%5D=#{subject}&discussion%%5Bbody%%5D=#{body}", callback


module.exports = LRHelp
