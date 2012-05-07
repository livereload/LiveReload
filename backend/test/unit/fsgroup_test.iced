assert = require 'assert'
FSGroup = require '../../lib/vfs/fsgroup'


describe "FSGroup", ->

  describe "with a single file name", ->

    group = FSGroup.parse("foo.txt")

    it "should match a file with that name", ->
      assert.ok group.contains "foo.txt"

    it "should not match a file with a different name", ->
      assert.ok !group.contains "bar.txt"

    it "should match a file with that name in a subdirectory", ->
      assert.ok group.contains "some/dir/foo.txt"

    it "should not match a file in a directory with that name", ->
      assert.ok !group.contains "bar.txt/another.js"


  describe "with an extension only (*.txt)", ->

    group = FSGroup.parse("*.txt")

    it "should match a file with that extension", ->
      assert.ok group.contains "foo.txt"

    it "should match a file with that extension in a subdirectory", ->
      assert.ok group.contains "some/dir/foo.txt"

    it "should not match a file with a different extension", ->
      assert.ok !group.contains "foo.js"


  describe "with an asterisk inside the name (foo*oob)", ->

    group = FSGroup.parse("foo*oob")

    it "should match a file like fooqweoob", ->
      assert.ok group.contains "fooqweoob"

    it "should match a file like foooob", ->
      assert.ok group.contains "foooob"

    it "should not match a file with overlapping prefix/suffix (like foob)", ->
      assert.ok !group.contains "foob"

    it "should not match an unrelated file", ->
      assert.ok !group.contains "foo.js"


  describe "with an asterisk alone", ->

    group = FSGroup.parse("*")

    it "should match any file", ->
      assert.ok group.contains "qwerty.txt"

    it "should match any file in any directory", ->
      assert.ok group.contains "some/dir/qwerty.txt"


  describe "with a directory name followed by an asterisk (dir/*)", ->

    group = FSGroup.parse("some/dir/*")

    it "should match any file in that directory", ->
      assert.ok group.contains "some/dir/qwerty.txt"

    it "should not match a file in a subdirectory of that directory", ->
      assert.ok group.contains "some/dir/subdir/qwerty.txt"

    it "should not match a file in another directory", ->
      assert.ok group.contains "elsewhere/qwerty.txt"
