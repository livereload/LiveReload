MessageFormat = require './format'

module.exports =
class MessageParser

  constructor: ({ errors, warnings }) ->
    @formats  = @_createFormats('warning', warnings or [])
      .concat   @_createFormats('error',   errors   or [])

  _createFormats: (type, patterns) ->
    for pattern in patterns
      new MessageFormat pattern, @_createMessage.bind(this, type)

  _createMessage: (type) ->{ type }

  parse: (text) ->
    all  = []
    text = text.trim() + "\n"

    for format in @formats
      break if text is "\n"

      { text, messages } = format.scan(text)
      if messages.length > 0
        all.push.apply(all, messages)
        text = text.trim() + "\n"

    return { messages: all, unparsed: text.trim() }
