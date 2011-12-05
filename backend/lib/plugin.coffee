fs    = require 'fs'
path  = require 'path'
util  = require 'util'
plist = require 'plist'
async = require 'async'

{ Compiler } = require './tool'


class Plugin
  constructor: (@folder) ->

  initialize: (callback) ->
    @compilers = {}

    plist.parseFile "#{@folder}/Info.plist", (err, obj) =>
      return callback(err) if err

      @manifest = obj[0]
      # console.log "Loaded manifest at #{@folder} with #{@manifest.LRCompilers.length} compilers"

      for compilerManifest in @manifest.LRCompilers
        compiler = new Compiler(this, compilerManifest)
        @compilers[compiler.name] = compiler

      callback(err)


loadPlugin = (folder, callback) ->
  plugin = new Plugin(folder)
  plugin.initialize (err) ->
    return callback(err) if err
    callback(null, plugin)


class PluginManager

  constructor: (@folders) ->

  rescan: (callback) ->
    pluginFolders = []
    for folder in @folders
      for entry in fs.readdirSync(folder) when entry.endsWith('.lrplugin')
        pluginFolders.push path.join(folder, entry)

    async.map pluginFolders, loadPlugin, (err, result) =>
      return callback(err) if err

      @plugins = result

      @compilers = {}
      for plugin in @plugins
        Object.merge @compilers, plugin.compilers

      return callback(null)


exports.PluginManager = PluginManager
exports.Plugin = Plugin
