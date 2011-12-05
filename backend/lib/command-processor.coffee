
class exports.CommandProcessor

  constructor: (@send) ->

  'init': (data, callback) ->
    @pluginManager = new PluginManager(data.pluginFolders)
    @pluginManager.rescan (err) ->
      callback(err)
