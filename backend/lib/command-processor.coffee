
class exports.CommandProcessor

  constructor: (@send) ->

  'init': (data, callback) ->
    throw new Error("init requires pluginFolders") unless data.pluginFolders
    @pluginManager = new PluginManager(data.pluginFolders)
    @pluginManager.rescan (err) ->
      callback(err, command: "init.ok")
