
module.exports = class ImportGraph

  findRootReferencingPaths: (path) ->
    null

  resolveToRoots: (path) ->
    if roots = @findRootReferencingPaths(path)
      roots
    else
      [ path ]
