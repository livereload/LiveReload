R = require '../reactive'

module.exports = class LRSettings extends R.Entity

  constructor: (@memento={}) ->
    super()

    @__defprop 'customExtensionsToMonitor', []
