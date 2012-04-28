
makeObject = (key, value) ->
  object = {}
  object[key] = value
  return object

splitSelector = (selector) ->
  if selector
    selector.split ' '
  else
    []

selectorToTree = (selector, value) ->
  for key in selector.split(' ').reverse()
    value = makeObject(key, value)
  return value

module.exports = {
  makeObject
  splitSelector
  selectorToTree
}
