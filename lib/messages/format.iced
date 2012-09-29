

module.exports =
class MessageFormat

  @WILDCARDS =
    file:    '[^\\n]+?'
    line:    '\\d+'
    message: '\\S[^\\n]+?'

  constructor: (@pattern) ->
    @indices   = {}
    @overrides = {}
    @used      = no

    index = 1
    @processedPattern = @pattern.replace(/<ESC>/g, '').replace /// \(\( ([\w-]+) (?: : (.*?) )? \)\) ///gm, (_, name, content) =>
      if name is 'message-override'
        @overrides['message'] = content
        return ''

      if replacement = MessageFormat.WILDCARDS[name]
        @indices[name] = index
      else
        throw new Error("Unknown wildcard: '#{name}'")
      index++

      if content
        content = content.replace '***', replacement
        return "(#{content})"
      else
        return "(#{replacement})"

    # console.log @pattern
    # console.log @processedPattern
    @regexp = new RegExp(@processedPattern, 'ig')

  scan: (text) ->
    messages = []
    text.replace @regexp, (match...) =>

      # console.log @pattern
      # console.log @processedPattern
      # console.log @indices
      # console.log match

      message = {} #new ToolMessage()
      for key, index of @indices
        message[key] = match[index]
      for key, value of @overrides
        message[key] = value.replace('***', message[key] || '')
      messages.push message

      ""

    { text, messages }
