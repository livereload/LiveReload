{ ok, equal, deepEqual } = require 'assert'
{ addTrailingSlash, addLeadingSlash, removeTrailingSlash, removeLeadingSlash } = require "../#{process.env.JSLIB or 'lib'}/index"

describe "pathutil", ->

  describe "#addTrailingSlash", ->

    it "should append a slash to /foo", ->
      equal addTrailingSlash('/foo'), '/foo/'

    it "should return /foo/ unchanged", ->
      equal addTrailingSlash('/foo/'), '/foo/'

    it "should return a root path ('/') unchanged", ->
      equal addTrailingSlash('/'), '/'

    it "should return an empty path unchanged", ->
      equal addTrailingSlash(''), ''

  describe "#removeTrailingSlash", ->

    it "should remove a slash from /foo/", ->
      equal removeTrailingSlash('/foo/'), '/foo'

    it "should return /foo unchanged", ->
      equal removeTrailingSlash('/foo'), '/foo'

    it "should return a root path ('/') unchanged", ->
      equal removeTrailingSlash('/'), '/'

    it "should return an empty path unchanged", ->
      equal removeTrailingSlash(''), ''

  describe "#addLeadingSlash", ->

    it "should append a slash to foo", ->
      equal addLeadingSlash('foo'), '/foo'

    it "should return /foo unchanged", ->
      equal addLeadingSlash('/foo'), '/foo'

    it "should return a root path ('/') unchanged", ->
      equal addLeadingSlash('/'), '/'

    it.skip "should return an empty path unchanged", ->
      equal addLeadingSlash(''), ''

  describe "#removeLeadingSlash", ->

    it "should remove a slash from /foo/", ->
      equal removeLeadingSlash('/foo/'), 'foo/'

    it "should return foo/ unchanged", ->
      equal removeLeadingSlash('foo/'), 'foo/'

    it.skip "should return a root path ('/') unchanged", ->
      equal removeLeadingSlash('/'), '/'

    it.skip "should return an empty path unchanged", ->
      equal removeLeadingSlash(''), ''
