
module.exports = class Stylesheet

  constructor: (@selectorsToProperties) ->
    # selectors are only annotated the first time they are used
    @annotatedSelectors = {}

  annotate: (payload, path=[], always=no) ->
    selector = path.join(' ')
    if props = @selectorsToProperties[selector]
      if always or !@annotatedSelectors[selector]
        @annotatedSelectors[selector] = yes unless always
        Object.merge payload, props, false, false  # shallow merge, don't overwrite keys

    for own key, value of payload
      if Object.isObject(value)
        isProperty = key.match(/^[#%.]/)
        # property data is completely overwritten, so always annotate it

        path.push(key)
        @annotate value, path, always || isProperty
        path.pop()

        if Object.isString(value.tags)
          value.tags = value.tags.trim().split(/\s+/)

        for tag in value.tags || []
          path.push(tag)
          @annotate value, path, always || isProperty
          path.pop()

      # TODO: if this is a deletion request (value == false), mark the corresponding selectors as unannotated

    return payload
