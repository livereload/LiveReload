
module.exports = class LRApplicationUI

  constructor: ->
    @mainwnd = new (require './mainwnd')()

  start: (callback) ->
    @mainwnd.show(callback)
