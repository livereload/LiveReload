
mkdir = (tree, path) ->
  for item in path
    tree = (tree[item] ||= {})
  tree

camelize = (string, first=true) ->
  string.replace /(^|_)([^_]+)/g, (match, pre, word, index) ->
    capitalize = (first) || (index > 0)
    if capitalize
      word.substr(0, 1).toUpperCase() + word.substr(1)
    else
      word


exports.ApiTree = class ApiTree

  mount: (message, value) ->
    [path..., name] = message.split('.').map((component) -> camelize(component, no))
    parent = mkdir(this, path)
    parent[name] = value


exports.createRemoteApiTree = (messages, func) ->
  tree = new ApiTree()
  for message in messages
    tree.mount message, func(message)
  tree
