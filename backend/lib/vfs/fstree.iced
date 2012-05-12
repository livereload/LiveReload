log = require('dreamlog')(module)
R = require '../reactive'
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


class FSTreeListQuery

  constructor: (@tree, @list) ->
    R.hook this, @list.toString()
    @result = @_execute()

  _firstSubscriberAdded: ->
    @tree.queries.push @__uid, this

  _lastSubscriberRemoved: ->
    if (index = @tree.queries.indexOf(@__uid)) >= 0
      @tree.queries.splice index, 2

  _execute: ->
    @tree.paths.filter (path) => @list.matches(path)

  treeBuilt: ->
    @result = @_execute()
    @notifySubscribers()

  treeChanged: (path) ->
    matches = (@list.matches(path))
    index = @result.indexOf(path)
    if matches != (index >= 0)
      if matches
        @result.push path
      else
        @result.splice index, 1
      @notifySubscribers(path)

R.mixin.dependable(FSTreeListQuery)


collectPaths = (node, paths=[]) ->
  paths.push node.name
  for child in node.children || []
    collectPaths child, paths
  return paths

class FSTree

  constructor: ->
    @root = { name: "", type: 'dir' }
    @paths = []
    @queries = []

  initialize: (tree) ->
    @root = tree
    @paths = collectPaths(@root)
    log.debug "Tree initialized with paths: " + JSON.stringify(@paths)
    for query in @queries when typeof query isnt 'string'
      query.treeBuilt()

  createQuery: (list) ->
    new FSTreeListQuery(this, list)

  query: (list) ->
    new FSTreeGroupDependency(this, list).infect()
    return

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
    for query in @queries when typeof query isnt 'string'
      query.treeChanged(path)

  remove: (path) ->
    if path in @paths
      @paths.remove path
      for query in @queries when typeof query isnt 'string'
        query.treeChanged(path)

module.exports = FSTree
