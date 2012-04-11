require 'sugar'

LRApplication        = require '../lib/app/application'
{ MockRpcTransport } = require '../test/mocks'


flattenHash = (object, sep='.', prefix='', result={}) ->
  for own key, value of object
    newKey = if prefix then "#{prefix}#{sep}#{key}" else key

    if (typeof value is 'object') && value.constructor is Object
      flattenHash value, sep, newKey, result
    else
      result[newKey] = value

  return result


application = new LRApplication(new MockRpcTransport())

for k in Object.keys(flattenHash(application._api))
  process.stdout.write "#{k}\n"
