{EventType} = require '../lib/eventtypes'


module.exports = Hierarchy = (object={}, levels=1) ->
  object.__proto__ = Hierarchy.prototype
  if levels > 1
    for own k, v of object
      Hierarchy(v, levels - 1)
  return object


Hierarchy::add = (key, source) ->
  if source instanceof Hierarchy
    if key of this
      this[key].merge source
    else
      this[key]   =   source
  else
    type = EventType.of(key)

    if key of this
      type.reduce this[key], source
    else
      this[key] = type.clone(source)
  return this


Hierarchy::merge = merge = (source) ->
  unless source instanceof Hierarchy
    throw new Error("Attempt to merge a non-hierarchy to a hierarchy")
  for own key, data of source
    @add key, data
  return this
