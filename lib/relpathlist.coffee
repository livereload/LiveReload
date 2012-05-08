RelPathSpec = require './relpathspec'

class RelPathList

  constructor: ->
    @specs = []

  include: (spec) ->
    @specs.push [yes, spec]
    return this

  exclude: (spec) ->
    @specs.push [no, spec]
    return this

  membership: (path, isDir) ->
    answer = null
    for [isIncluded, spec] in @specs
      if spec.matches(path, isDir)
        answer = isIncluded
    answer

  matches: (path, isDir) ->
    @membership(path, isDir) ? no

  toString: -> ((if isIncluded then '' else '!') + spec for [isIncluded, spec] in @specs).join(" ")


RelPathList.isSkippedLine = (line) ->

RelPathList.parseLine = (list, line) ->
  line = line.trim()
  if line[0] is '!'
    return new RelPathNotList(RelPathList.parseLine(line.substr(1)))

  directoriesOnly = no
  if line.endsWith '/'
    directoriesOnly = yes
    line = line.to(-1)

  if line.indexOf('/') >= 0
    name = RelPath.basename(line)
    dir = RelPath.dirname(line)
    new RelPathDirList(name, directoriesOnly, dir)
  else
    new RelPathNameList(line, directoriesOnly)


RelPathList.parse = (lines) ->
  if typeof lines is 'string'
    lines = [lines]

  result = new RelPathList()
  for line in lines
    line = line.trim()
    continue if !line or line[0] == '#'

    if line[0] == '!'
      line = line.substr(1)
      result.exclude RelPathSpec.parseGitStyleSpec(line)
    else
      result.include RelPathSpec.parseGitStyleSpec(line)

  return result


module.exports = RelPathList
