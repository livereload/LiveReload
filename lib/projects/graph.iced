
Array_uniq = (array) ->
  item for item, index in array when array.indexOf(item, index + 1) < 0


module.exports =
class Graph

  constructor: ->
    @clear()


  contents: ->
    ((for nodeId in Object.keys(@_nodes).sort() when @_nodes[nodeId].outgoingIds.length > 0
          "#{nodeId} -> " + @_nodes[nodeId].outgoingIds.slice(0).sort().join(", ")
    ).concat(
      for nodeId in Object.keys(@_nodes).sort() when @_nodes[nodeId].incomingIds.length > 0
            "#{nodeId} <- " + @_nodes[nodeId].incomingIds.slice(0).sort().join(", ")
    ))

  toString: ->
    if (c = @contents()).length > 0
      "<\n" + ("  #{l}\n" for l in c).join("") + ">\n"
    else
      "<>\n"


  hasIncomingEdges: (destinationId) ->
    (node = @_nodes[destinationId]) and (node.incomingIds.length > 0)


  getIncomingNodes: (destinationId) ->
    if node = @_nodes[destinationId]
      node.incomingIds
    else
      []


  findSources: (destinationId) ->
    @_findSourcesDFS(destinationId, [], {})

  _findSourcesDFS: (nodeId, result, visited) ->
    visited[nodeId] = yes
    if node = @_nodes[nodeId]
      if node.incomingIds.length is 0
        result.push(nodeId)
      else
        for sourceId in node.incomingIds when not visited[sourceId]
          @_findSourcesDFS(sourceId, result, visited)
    return result


  clear: ->
    @_nodes = {}


  updateOutgoing: (sourceId, newDestinationIds) ->
    node = @_lookup(sourceId)

    # remove stale edges
    for destinationId, index in node.outgoingIds.slice(0)
      if newDestinationIds.indexOf(destinationId) < 0
        node.removeOutgoing(destinationId)
        @_removeIncomingEdge(sourceId, destinationId)

    # add new edges
    for destinationId in newDestinationIds
      if node.outgoingIds.indexOf(destinationId) < 0
        node.outgoingIds.push(destinationId)
        @_lookup(destinationId).addIncoming(sourceId)

    undefined


  remove: (nodeId) ->
    if node = @_nodes[nodeId]
      # remove incoming edges
      for sourceId in node.incomingIds
        @_removeOutgoingEdge(sourceId, nodeId)

      # remove outgoing edges
      for destinationId in node.outgoingIds
        @_removeIncomingEdge(nodeId, destinationId)

      delete @_nodes[nodeId]

    undefined


  _removeIncomingEdge: (sourceId, destinationId) ->
    if node = @_nodes[destinationId]
      node.removeIncoming(sourceId)
      if node.isEmpty()
        delete @_nodes[destinationId]
    undefined


  _removeOutgoingEdge: (sourceId, destinationId) ->
    if node = @_nodes[sourceId]
      node.removeOutgoing(destinationId)
      if node.isEmpty()
        delete @_nodes[sourceId]
    undefined


  _lookup: (nodeId) ->
    @_nodes[nodeId] or= new Node(nodeId)


class Node

  constructor: (@id) ->
    @incomingIds = []
    @outgoingIds = []

  addIncoming: (sourceId) ->
    if (index = @incomingIds.indexOf(sourceId)) < 0
      @incomingIds.push sourceId
    undefined

  addOutgoing: (destinationId) ->
    if (index = @outgoingIds.indexOf(destinationId)) < 0
      @outgoingIds.push destinationId
    undefined

  removeIncoming: (sourceId) ->
    if (index = @incomingIds.indexOf(sourceId)) >= 0
      @incomingIds.splice index, 1
    undefined

  removeOutgoing: (destinationId) ->
    if (index = @outgoingIds.indexOf(destinationId)) >= 0
      @outgoingIds.splice index, 1
    undefined

  isEmpty: ->
    (@incomingIds.length is 0) and (@outgoingIds.length is 0)
