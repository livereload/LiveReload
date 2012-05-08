{ RelPathList, RelPathSpec } = require 'pathspec'

class FSTreeDependency

  infect: ->
    #

  subscribe: ->

  unsubscribe: ->


class FSTreeGroupDependency extends FSTreeDependency

  constructor: (@tree, @list) ->


class FSTreePathDependency extends FSTreeDependency

  constructor: (@tree, @path) ->



class FSTree

  constructor: ->
    @root = { name: "", type: 'dir' }
    @paths = []

  initialize: (tree) ->
    @root = tree

  query: (list) ->
    new FSTreeGroupDependency(this, list).infect()
    return @paths.filter (path) -> list.matches(path)

  fileExists: (path) ->
    new FSTreePathDependency(this, path).infect()
    return path in @paths

  folderChildren: (path) ->
    list = new RelPathList()
    list.include RelPathSpec.parse(path + '/**')
    new FSTreeGroupDependency(this, list).infect()
    return @paths.filter (path) -> list.matches(path)

  touch: (path) ->
    unless path in @paths
      @paths.push path

  remove: (path) ->
    if path in @paths
      @paths.remove path

module.exports = FSTree
