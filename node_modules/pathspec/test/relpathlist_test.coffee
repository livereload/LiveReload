assert = require 'assert'
{ RelPathList } = require '../index'

tests = []
o = (spec, examples) -> tests.push [spec, examples]

o 'foo.txt', ['foo.txt', '!bar.txt', 'some/dir/foo.txt', 'foo.txt/another.js']
o '*.txt',   ['foo.txt', 'some/dir/foo.txt', '!foo.js']
o '*',       ['qwerty.txt', 'some/dir/qwerty.txt']

o 'some/dir/*', ['some/dir/qwerty.txt', '!some/dir', 'some/dir/subdir/qwerty.txt', '!elsewhere/qwerty.txt']
o '/some',      ['some', 'some/qwerty.txt', 'some/subdir/qwerty.txt', '!another', '!another/qwerty.txt']

o '*.txt !some/dir', ['qwerty.txt', 'another/qwerty.txt', 'some/qwerty.txt', '!some/dir/qwerty.txt', '!some/dir/subdir/qwerty.txt', '!another.js', 'dir.txt/qwerty.js', '!some/dir/subdir.txt/qwerty.js', 'some/directly/notexcluded.txt', 'some/directly.txt']

describe "RelPathList", ->

  for [specStr, examples] in tests
    do (specStr, examples) ->
      describe "like '#{specStr}'", ->
        spec = RelPathList.parse(specStr.split(' '))
        for example in examples
          do (example) ->
            if example[0] == '!'
              example = example.substr(1)
              it "should not match '#{example}'", ->
                assert.ok !spec.matches example
            else
              it "should match '#{example}'", ->
                assert.ok spec.matches example
