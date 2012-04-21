
module.exports = class LRPreferences

  constructor: ->

  loadNativePreference: (key, callback) ->
    LR.client.preferences.read { key }, callback

  loadLegacyModel: (callback) ->
    @loadNativePreference "projects20a3", callback
    # await loadNativePreference "projects20a3", defer(err, value)
    # return callback(err) if err


  getSetting: (name, callback) ->
    callback(null, null)

  setSetting: (name, value, callback) ->
    callback?(null)
