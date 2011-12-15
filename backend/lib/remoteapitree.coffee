
mkdir = (tree, path) ->
  for item in path
    tree = (tree[item] ||= {})
  tree


class ApiTree

  mount: (message, value) ->
    [path..., name] = message.split('.')
    parent = mkdir(this, path)
    parent[name] = value


exports.createRemoteApiTree = (messages, func) ->
  tree = new ApiTree()
  for message in messages
    tree.mount message, func(message)
  tree
