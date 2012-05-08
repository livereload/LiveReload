assert = require 'assert'
{ Mask } = require '../index'


describe "Mask", ->

  describe "with a single file name", ->

    mask = Mask.parse("foo.txt")

    it "should match a file with that name", ->
      assert.ok mask.matches "foo.txt"

    it "should not match a file with a different name", ->
      assert.ok !mask.matches "bar.txt"


  describe "with an extension only (*.txt)", ->

    mask = Mask.parse("*.txt")

    it "should match a file with that extension", ->
      assert.ok mask.matches "foo.txt"

    it "should not match a file with a different extension", ->
      assert.ok !mask.matches "foo.js"


  describe "with an asterisk inside the name (foo*oob)", ->

    mask = Mask.parse("foo*oob")

    it "should match a file like fooqweoob", ->
      assert.ok mask.matches "fooqweoob"

    it "should match a file like foooob", ->
      assert.ok mask.matches "foooob"

    it "should not match a file with overlapping prefix/suffix (like foob)", ->
      assert.ok !mask.matches "foob"

    it "should not match an unrelated file", ->
      assert.ok !mask.matches "foo.js"


  describe "with an asterisk at the end of the name (foo*)", ->

    mask = Mask.parse("foo*")

    it "should match a file like fooqwe", ->
      assert.ok mask.matches "fooqwe"

    it "should match a file named foo", ->
      assert.ok mask.matches "foo"

    it "should not match an unrelated file", ->
      assert.ok !mask.matches "mooqwe"


  describe "with an asterisk alone", ->

    mask = Mask.parse("*")

    it "should match any file", ->
      assert.ok mask.matches "qwerty.txt"
