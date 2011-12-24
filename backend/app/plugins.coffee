{ PluginManager } = require '../lib/plugin'

_pluginManager = null

async = require 'async'

exports.init = (pluginFolders, callback) ->
  _pluginManager = new PluginManager(pluginFolders)
  _pluginManager.rescan callback
