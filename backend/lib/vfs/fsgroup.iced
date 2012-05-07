Path = require 'path'

class FSGroup

class FSGroup.Not extends FSGroup
  constructor: (@group) ->

  contains: (path) ->
    !@group.contains(path)

  toString: ->
    "!" + @group

FSGroup.Or = class FSOrGroup extends FSGroup
  constructor: (@groups=[]) ->

  contains: (path) ->
    @groups.any((g) -> g.contains(path))

  toString: ->
    ('' + g for g in @groups).join(", ")

FSGroup.Name = class FSNameGroup extends FSGroup
  constructor: (@name, @directoriesOnly) ->

  contains: (path) ->
    path = Path.basename(path)
    if (pos = @name.indexOf('*')) >= 0
      prefix = @name.substr(0, pos)
      suffix = @name.substr(pos + 1)
      return path.length >= @name.length - 1 and path.startsWith(prefix) and path.endsWith(suffix)
    else
      return path == @name

  toString: ->
    @name + (if @directoriesOnly then '<dir>' else '')

FSGroup.Dir = class FSDirGroup extends FSNameGroup
  constructor: (name, directoriesOnly, @dir) ->
    super(name, directoriesOnly)

  toString: ->
    @dir + '/' + super

FSGroup.isSkippedLine = (line) ->
  line = line.trim()
  return line.length == 0 or line[0] == '#'

FSGroup.parseLine = (line) ->
  line = line.trim()
  if line[0] is '!'
    return new FSNotGroup(FSGroup.parseLine(line.substr(1)))

  directoriesOnly = no
  if line.endsWith '/'
    directoriesOnly = yes
    line = line.to(-1)

  if line.indexOf('/') >= 0
    name = Path.basename(line)
    dir = Path.dirname(line)
    new FSDirGroup(name, directoriesOnly, dir)
  else
    new FSNameGroup(line, directoriesOnly)

FSGroup.parse = (lines) ->
  if typeof lines is 'string'
    return FSGroup.parseLine(lines)
  groups = (FSGroup.parse(line) for line in lines when !FSGroup.isSkippedLine(line))
  if groups.length is 1
    groups[0]
  else
    new FSOrGroup(groups)

FSGroup.childrenOfPath = (path) ->
  new FSDirGroup("*", no, path)

module.exports = FSGroup
