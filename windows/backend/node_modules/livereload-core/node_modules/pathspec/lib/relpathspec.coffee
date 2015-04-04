Mask = require './mask'


class PathComponents
  constructor: (@components, @isDir, @hasSlash) ->

  split: (delimiter, collapseConsecutiveDelimiters=yes) ->
    result = [[]]
    for component, index in @components
      if component == delimiter
        continue if collapseConsecutiveDelimiters and (index > 0) and @components[index - 1] == delimiter
        result.push []
      else
        result[result.length - 1].push component
    return result

PathComponents.parse = (string) ->
    if !string
      new PathComponents([], no)
    else
      components = string.split('/')
      isDir = (components[components.length - 1] is '')
      hasLeadingSlash = (components[0] is '')

      # kill empty components to get rid of any leading, trailing and duplicate slashes
      components = (c for c in components when c)
      hasSlash = hasLeadingSlash || components.length > 1

      new PathComponents(components, isDir, hasSlash)


class Subpath

  constructor: (@masks) ->

  matchesAt: (components, startIndex) ->
    return no if components.length < @masks.length

    for i in [0 ... @masks.length]
      unless @masks[i].matches(components[startIndex + i])
        return no
    return yes

  matchesEntirely: (components) ->
    (components.length == @masks.length) and @matchesAt(components, 0)

  matchesAtStart: (components) ->
    @matchesAt(components, 0)

  matchesAtEnd: (components) ->
    @matchesAt(components, components.length - @masks.length)

  find: (components) ->
    for i in [0 .. components.length - @masks.length]
      if @matchesAt(components, i)
        return i
    return -1

  matchAndRemoveAtStart: (components) ->
    if @matchesAtStart(components)
      components.slice(@masks.length)
    else
      null

  matchAndRemoveAtEnd: (components) ->
    if @matchesAtEnd(components)
      components.slice(0, components.length - @masks.length)
    else
      null

  findAndRemove: (components) ->
    if (index = @find(components)) >= 0
      components.slice(index + @masks.length)
    else
      null

  toString: -> (mask.toString() for mask in @masks).join('/')


class RelPathSpec

  matches: (path, isDir=no) ->
    parsed = PathComponents.parse(path)

    if @mustBeDir and not (isDir || parsed.isDir)
      return no

    @matchesComponents(parsed.components)


class SingleSubpathRelPathSpec extends RelPathSpec

  constructor: (@subpath, @mustBeDir) ->

  matchesComponents: (components) ->
    @subpath.matchesEntirely(components)


class StarStarRelPathSpec extends RelPathSpec
  constructor: (@subpaths, @mustBeDir) ->
    @prefix = @subpaths.shift()
    @suffix = @subpaths.pop()

  matchesComponents: (components) ->
    unless components = @prefix.matchAndRemoveAtStart(components)
      return no
    unless components = @suffix.matchAndRemoveAtEnd(components)
      return no
    for subpath in @subpaths
      unless components = subpath.findAndRemove(components)
        return no
    return yes

  toString: -> (subpath.toString() for subpath in [@prefix].concat(@subpaths).concat([@suffix])).join('/**/').replace(/^\/\*\*|\*\*\/$/g, '**')


RelPathSpec.parse = (path, gitStyle=no) ->
  parsed = PathComponents.parse(path)
  subpaths = for subcomponents in parsed.split('**')
    new Subpath((Mask.parse(component) for component in subcomponents))

  if gitStyle
    # prepend '**/' if the path does not contain any slashes (except for maybe a trailing slash, which indicates that we are expecting a directory)
    if !parsed.hasSlash
      subpaths.unshift new Subpath([])
    # append '/**' unless it's already there
    unless subpaths[subpaths.length - 1].masks.length == 0
      subpaths.push new Subpath([])

  if subpaths.length is 1
    new SingleSubpathRelPathSpec(subpaths[0], parsed.isDir)
  else
    new StarStarRelPathSpec(subpaths, parsed.isDir)

RelPathSpec.parseGitStyleSpec = (spec) -> RelPathSpec.parse(spec, yes)

module.exports = RelPathSpec
