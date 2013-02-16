debug = require('debug')('livereload:context')
Path    = require 'path'
Session = require 'livereload-core'

RPC = require './rpc/rpc'

LRPreferences = require './services/preferences'
LRStats       = require './services/stats'

class LiveReloadContext

  constructor: ->
    @universe = new Session.R.Universe()
    @session = @universe.create(Session)

    @paths = {}
    @paths.root = Path.dirname(__dirname)
    @paths.rpc  = Path.join(@paths.root, 'rpc-api')

    @paths.bundledPlugins = process.env.LRBundledPluginsOverride || Path.join(@paths.root, 'plugins')
    @session.addPluginFolder @paths.bundledPlugins

  setupRpc: (transport) ->
    @rpc = new RPC(transport)

  setupRuntime: ({ @version, appDataDir }) ->
    @paths.appData = appDataDir
    debug "setupRuntime: version = #{@version}, paths.appData = #{@paths.appData}"

    @preferences = new LRPreferences(@paths.appData)
    @stats = new LRStats(@preferences)

module.exports = LiveReloadContext
