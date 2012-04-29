
__convertTreeToBush = (tree, bushes, siblings) ->
  bush = Object.clone(tree)
  delete bush.id
  bush.children = []

  siblings.push tree.id
  bushes[tree.id] = bush

  for subtree in tree.children || []
    __convertTreeToBush subtree, bushes, bush.children

  return

exports.convertForeshToBushes = (forest) ->
  bushes = '#root': children: []
  for tree in forest
    __convertTreeToBush tree, bushes, bushes['#root'].children
  return bushes
