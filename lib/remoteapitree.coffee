
mkdir = (tree, path) ->
  for item in path
    tree = (tree[item] ||= {})
  tree


exports.ApiTree = class ApiTree

  mount: (message, value) ->
    [path..., name] = message.split('.').map((component) -> component.camelize(no))
    parent = mkdir(this, path)
    parent[name] = value


exports.createRemoteApiTree = (messages, func) ->
  tree = new ApiTree()
  for message in messages
    tree.mount message, func(message)
  tree
