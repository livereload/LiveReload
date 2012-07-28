{ PluginManager } = require '../lib/plugin'

_pluginManager = null

exports.init = (pluginFolders, callback) ->
  _pluginManager = new PluginManager(pluginFolders)
  _pluginManager.rescan callback
