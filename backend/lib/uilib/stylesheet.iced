{ makeObject, splitSelector, selectorToTree } = require './util'

module.exports = class Stylesheet

  constructor: (@selectorsToProperties) ->
    # selectors are only annotated the first time they are used
    @annotatedSelectors = {}

  annotate: (payload) ->
    @__annotate payload

    LR.log.fyi "Stylesheet: " + JSON.stringify(@selectorsToProperties, null, 2)

    for own selector, props of @selectorsToProperties when selector.match(/^[ #a-zA-Z0-9-]+$/)  # IDs only
      if !@annotatedSelectors[selector]
        LR.log.fyi "Selector #{selector}, props: " + JSON.stringify(selectorToTree(selector, props), null, 2)
        Object.merge payload, selectorToTree(selector, props), true  # deep merge
        @annotatedSelectors[selector] = yes

    return


  __annotate: (payload, path=[], always=no) ->
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
        @__annotate value, path, always || isProperty
        path.pop()

        if Object.isString(value.tags)
          value.tags = value.tags.trim().split(/\s+/)

        for tag in value.tags || []
          path.push(tag)
          @__annotate value, path, always || isProperty
          path.pop()

      # TODO: if this is a deletion request (value == false), mark the corresponding selectors as unannotated

    return payload
