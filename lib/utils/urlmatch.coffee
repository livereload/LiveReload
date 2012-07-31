Url = require 'url'

RegExp_escape = (s) ->
  s.replace /// [-/\\^$*+?.()|[\]{}] ///g, '\\$&'

RegExp_fromPattern = (pattern, prefix, suffix) ->
  new RegExp(prefix + RegExp_escape(pattern).replace(/^livereloadany\\\./, '(?:.*\\.)?').replace(/livereloadany/g, '.*') + suffix)

urlmatch = (patternString, actualString) ->
  if patternString.indexOf('://') < 0
    patternString = "*://" + patternString

  pattern = Url.parse(patternString.replace(/\*/g, 'livereloadany'))
  actual  = Url.parse(actualString)

  # host is required; no host => most likely a parsing error
  return no if !pattern.host

  # host names match?
  return no if !RegExp_fromPattern(pattern.hostname, '^', '$').test(actual.hostname)

  # ports match?
  actual.port ?= { 'http:': '80', 'https:': 443 }[actual.protocol]
  return no if pattern.port and !RegExp_fromPattern(pattern.port, '^', '$').test(actual.port)

  # protocols match?
  return no if pattern.protocol and !RegExp_fromPattern(pattern.protocol, '^', '$').test(actual.protocol)

  # paths match?
  return no if pattern.pathname and !RegExp_fromPattern(pattern.pathname, '^', '').test(actual.pathname)

  return yes


module.exports = urlmatch
