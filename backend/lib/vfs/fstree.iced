FSGroup = require './fsgroup'

class FSTreeDependency

  infect: ->
    #

  subscribe: ->

  unsubscribe: ->


class FSTreeGroupDependency extends FSTreeDependency

  constructor: (@tree, @group) ->


class FSTreePathDependency extends FSTreeDependency

  constructor: (@tree, @path) ->



class FSTree

  constructor: ->
    @paths = []

  query: (group) ->
    new FSTreeGroupDependency(this, group).infect()
    return @paths.filter (path) -> group.contains(path)

  fileExists: (path) ->
    new FSTreePathDependency(this, path).infect()
    return path in @paths

  folderChildren: (path) ->
    group = FSGroup.childrenOfPath(path)
    new FSTreeGroupDependency(this, group).infect()
    return @paths.filter (path) -> group.contains(path)

  touch: (path) ->
    unless path in @paths
      @paths.push path

  remove: (path) ->
    if path in @paths
      @paths.remove path

module.exports = FSTree
