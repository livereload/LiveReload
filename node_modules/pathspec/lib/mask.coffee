{ RegExp_escape } = require './util'

class FSMask

class FSTrivialMask extends FSMask
  constructor: (@name) ->

  matches: (candidate) ->
    candidate == @name

  toString: -> @name

class FSWildcardMask extends FSMask
  constructor: (wildcard) ->
    if typeof wildcard is 'string'
      @wildcard = wildcard
      parts = wildcard.split('*')
    else
      parts = wildcard
      @wildcard = parts.join('*')

    @len    = (p.length for p in parts).reduce (a,b) -> a+b
    @regexp = new RegExp('^' + (RegExp_escape(p) for p in parts).join('.*?') + '$')

  matches: (candidate) ->
    candidate.length >= @len and @regexp.test(candidate)

  toString: -> @wildcard

FSMask.parse = (wildcard) ->
  if wildcard.indexOf('*') >= 0
    new FSWildcardMask(wildcard)
  else
    new FSTrivialMask(wildcard)

module.exports = FSMask
