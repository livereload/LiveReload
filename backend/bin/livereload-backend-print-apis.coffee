apitree = require 'apitree'
path    = require 'path'

flattenHash = (object, sep='.', prefix='', result={}) ->
  for own key, value of object
    newKey = if prefix then "#{prefix}#{sep}#{key}" else key

    if (typeof value is 'object') && value.constructor is Object
      flattenHash value, sep, newKey, result
    else
      result[newKey] = value

  return result

loadItem = (path) -> require(path).api || {}

tree = flattenHash(apitree.createApiTree(path.join(__dirname, '../app'), { loadItem }))
for k in Object.keys(tree)
  process.stdout.write "#{k}\n"
