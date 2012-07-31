Session = require 'livereload-core'

class LiveReloadContext

  constructor: ->
    @session = new Session()

module.exports = LiveReloadContext
