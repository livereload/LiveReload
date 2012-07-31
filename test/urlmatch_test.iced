assert = require 'assert'

urlmatch = require '../lib/utils/urlmatch'

describe "urlmatch", ->

  o = (pattern, included, excluded) ->

    describe "with pattern '#{pattern}'", ->

      for url in included
        do (url) ->
          it "should match '#{url}'", ->
            assert.ok urlmatch(pattern, url)

      for url in excluded
        do (url) ->
          it "shouldn't match '#{url}'", ->
            assert.ok !urlmatch(pattern, url)

  o 'livereload.com', [
    'http://livereload.com'
    'http://livereload.com/'
    'http://livereload.com:80'
    'http://livereload.com:3000'
    'http://livereload.com/help/'
    'https://livereload.com'
  ], [
    'http://example.com/'
    'http://foo.livereload.com'
    'https://foo.livereload.com/'
  ]

  o 'http://livereload.com', [
    'http://livereload.com'
    'http://livereload.com/'
    'http://livereload.com:80'
    'http://livereload.com:3000'
    'http://livereload.com/help/'
  ], [
    'http://example.com/'
    'https://livereload.com'
    'https://foo.livereload.com/'
    'http://foo.bar.livereload.com'
    'http://foo.bar.livereload.com/help/'
  ]

  o 'https://livereload.com', [
    'https://livereload.com'
  ], [
    'http://example.com/'
    'http://livereload.com'
  ]

  o 'livereload.com:3000', [
    'http://livereload.com:3000'
    'http://livereload.com:3000/help/'
  ], [
    'http://example.com/'
    'http://foo.bar.livereload.com'
    'http://foo.bar.livereload.com/help/'
    'https://livereload.com'
    'http://livereload.com/'
    'http://livereload.com:80'
  ]

  o 'livereload.com:80', [
    'http://livereload.com/'
    'http://livereload.com:80'
    'http://livereload.com/help/'
    'http://livereload.com:80'
    'http://livereload.com:80/help/'
  ], [
    'http://example.com/'
    'https://livereload.com'
    'http://livereload.com:3000'
    'http://foo.bar.livereload.com'
    'http://foo.bar.livereload.com/help/'
  ]

  o '*.livereload.com', [
    'http://livereload.com/'
    'https://livereload.com'
    'http://foo.livereload.com'
    'https://foo.livereload.com'
    'http://foo.bar.livereload.com'
  ], [
    'http://example.com/'
  ]

  o 'livereload.com/help', [
    'http://livereload.com/help/index.html'
    'https://livereload.com/help/index.html'
    'http://livereload.com:3000/help/index.html'
    'http://livereload.com:3000/help/index.html'
    'http://livereload.com:3000/help-topics/index.html'
  ], [
    'http://livereload.com/'
    'http://example.com/'
    'http://example.com/help/index.html'
    'http://foo.livereload.com/help/index.html'
  ]
