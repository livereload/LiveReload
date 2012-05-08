assert = require 'assert'
{ RelPathSpec } = require '../index'

tests = []
o = (spec, examples) -> tests.push [spec, examples]

o 'foo.txt', ['foo.txt', '!bar.txt', '!bar.txt/another.js']
o '*.txt', ['foo.txt', '!some/dir/foo.txt', '!foo.js']
o '*', ['qwerty.txt', '!some/dir/qwerty.txt']
o '**', ['qwerty.txt', 'dir/qwerty.txt', 'some/dir/qwerty.txt']
o '**/*', ['qwerty.txt', 'dir/qwerty.txt', 'some/dir/qwerty.txt']
o 'some/dir/*', ['some/dir/qwerty.txt', '!some/dir', '!some/dir/subdir/qwerty.txt', '!elsewhere/qwerty.txt']
o '/some', ['some', '!some/qwerty.txt', '!another/qwerty.txt']
o '/some/**', ['some', 'some/qwerty.txt', '!another/qwerty.txt']
o 'foo.txt/**', ['foo.txt', '!bar.txt', '!some/dir/foo.txt', 'foo.txt/another.js']
o '**/foo.txt', ['foo.txt', '!bar.txt', 'some/dir/foo.txt', '!foo.txt/another.js']
o '**/foo.txt/**', ['foo.txt', '!bar.txt', 'some/dir/foo.txt', 'foo.txt/another.js', 'some/dir/foo.txt/another.js']
o 'foo/**/bar.txt', ['foo/bar.txt', 'foo/dir/bar.txt', 'foo/some/dir/bar.txt', '!some/dir/bar.txt', '!foo/another.txt', '!foo/some/dir/another.txt']
o 'foo/**/boz/**/bar.txt', ['foo/boz/bar.txt', 'foo/some/boz/bar.txt', 'foo/boz/some/bar.txt', 'foo/some/boz/dir/bar.txt', 'foo/many/extra/boz/dir/components/bar.txt', '!foo/bar.txt', '!foo/dir/bar.txt', '!foo/some/dir/bar.txt', '!some/sub/boz/dir/bar.txt', '!foo/sub/boz/another.txt']


describe "RelPathSpec", ->

  for [specStr, examples] in tests
    do (specStr, examples) ->
      describe "like '#{specStr}'", ->
        spec = RelPathSpec.parse(specStr)
        for example in examples
          do (example) ->
            if example[0] == '!'
              example = example.substr(1)
              it "should not match '#{example}'", ->
                assert.ok !spec.matches example
            else
              it "should match '#{example}'", ->
                assert.ok spec.matches example

  describe ".parseGitStyleSpec", ->

    o = (spec, original) ->
      it "should parse '#{spec}' as if it was '#{original}'", ->
        assert.equal RelPathSpec.parseGitStyleSpec(spec).toString(), original

    o 'foo', '**/foo/**'
    o '/foo', 'foo/**'
    o 'foo/**', 'foo/**'
    o 'foo/bar', 'foo/bar/**'
    o '/foo/bar', 'foo/bar/**'
    o 'foo/bar/**', 'foo/bar/**'
    o 'foo/**/bar', 'foo/**/bar/**'
