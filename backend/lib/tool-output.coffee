util = require 'util'


WILDCARDS =
  file:    '[^\\n]+?'
  line:    '\\d+'
  message: '\\S[^\\n]+?'


class ToolMessage

  constructor: ->
    @message = @file = @line = null

  toString: -> util.inspect(this)

  toJSON: -> { @message, @file, @line }


exports.ToolOutput = class ToolOutput

  constructor: (@raw) ->
    @warnings = []
    @error = null
    @parsed = no

  toString: -> util.inspect({ @warnings, @error })

  toJSON: -> {
    @raw
    warnings: @warnings.map('toJSON')
    error:    @error?.toJSON()
  }


class MessageFormat

  constructor: (@pattern) ->
    @indices   = {}
    @overrides = {}
    @used      = no

    index = 1
    @processedPattern = @pattern.replace(/<ESC>/g, '').replace /// \(\( ([\w-]+) (?: : (.*?) )? \)\) ///gm, (_, name, content) =>
      if name is 'message-override'
        @overrides['message'] = content
        return ''

      if replacement = WILDCARDS[name]
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

  forEachMatch: (text, callback) ->
    text.replace @regexp, (match...) =>

      # console.log @pattern
      # console.log @processedPattern
      # console.log @indices
      # console.log match

      message = new ToolMessage()
      for key, index of @indices
        message[key] = match[index]
      for key, value of @overrides
        message[key] = value.replace('***', message[key] || '')
      callback(message)

      ""

class exports.MessageParser

  constructor: (compilerManifest) ->
    @errorFormats   = (new MessageFormat(pattern) for pattern in compilerManifest.Errors)
    @warningFormats = (new MessageFormat(pattern) for pattern in compilerManifest.Warnings || [])

  parse: (text) ->
    output = new ToolOutput(text)

    text = text.trim() + "\n"

    for format in @warningFormats
      text = format.forEachMatch text, (message) ->
        output.warnings.push message

    if text.trim().length == 0
      output.parsed = yes
    else
      for format in @errorFormats
        text = format.forEachMatch text, (message) ->
          unless output.error
            output.error = message
            output.parsed = yes

    output.parsed = yes if output.warnings.length > 0

    return output
