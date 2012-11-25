{ ok, equal, deepEqual } = require 'assert'
{ PlaPath } = require "../#{process.env.JSLIB or 'lib'}/index"


describeAnyPath = (AnyPath, options) ->

  n = (src, expected) ->
    comment = "should normalize '#{src}' into " + (if expected is src then "itself" else "'#{expected}'")
    it comment, ->
      equal AnyPath.normalize(src), expected

  _s = (result, sub, sup) ->
    comment = (if result then "should" else "shouldn't") + " consider '#{sub}' a subpath of '#{sup}'"
    it comment, ->
      ok AnyPath.isSubpath(sub, sup) == result
  s = _s.bind(null, yes)
  S = _s.bind(null, no)

  T = (a, b, res) ->
    comment = "should return #{res} for '#{a}' and '#{b}'"
    it comment, ->
      equal AnyPath.numberOfMatchingTrailingComponents(a, b), res

  return { n, s, S, T }


describe "PlaPath", ->

  {n, s, S, T} = describeAnyPath(PlaPath)

  describe '#normalize', ->
    n 'foo', 'foo'
    n 'foo/bar', 'foo/bar'
    n '/foo/bar', 'foo/bar'
    n 'foo/bar/', 'foo/bar/'

  describe '#isSubpath', ->
    describe 'with empty paths', ->
      s '', ''
      s 'foo', ''
      S '', 'foo'

    describe 'with simple paths', ->
      S 'foo', 'bar'
      s 'foo/bar', 'foo'
      s 'foo/bar/boz', 'foo'
      S 'foo/bar/boz', 'foo/goo'

    describe 'with trailing slashes', ->
      # s 'foo', 'foo/'
      s 'foo/', 'foo'

    describe 'with edge case paths', ->
      s 'foo', 'foo'

  describe '#numberOfMatchingTrailingComponents', ->
    T 'foo', 'foo', 1
    T 'foo', 'bar', 0

    T 'foo/bar', 'foo/bar', 2
    T 'foo/boz', 'bar/boz', 1
    T 'bar', 'foo/bar', 1

    T 'foo/bar/boz', 'boo/bar/boz', 2

    T 'foo', '', 0
