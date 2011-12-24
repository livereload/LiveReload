fs    = require 'fs'
Path  = require 'path'
util  = require 'util'
plist = require 'plist'
async = require 'async'

{ Compiler } = require './tool'


class Plugin
  constructor: (@folder) ->

  initialize: (callback) ->
    @compilers = {}

    @manifestFile = "#{@folder}/manifest.json"

    plistFile = "#{@folder}/Info.plist"
    if Path.existsSync(plistFile)
      plist.parseFile plistFile, (err, obj) =>
        fs.writeFileSync(@manifestFile, JSON.stringify(obj[0], null, 2))
        @parseManifest(callback)
    else
      @parseManifest(callback)

  parseManifest: (callback) ->
    try
      @processManifest JSON.parse(fs.readFileSync(@manifestFile, 'utf8')), callback
    catch e
      callback(e)

  processManifest: (@manifest, callback) ->
    for compilerManifest in @manifest.LRCompilers
      compiler = new Compiler(this, compilerManifest)
      @compilers[compiler.name] = compiler

    console.log "Loaded manifest at #{@folder} with #{@manifest.LRCompilers.length} compilers"
    callback(null)


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
        pluginFolders.push Path.join(folder, entry)

    async.map pluginFolders, loadPlugin, (err, result) =>
      return callback(err) if err

      @plugins = result

      @compilers = {}
      for plugin in @plugins
        Object.merge @compilers, plugin.compilers

      return callback(null)


exports.PluginManager = PluginManager
exports.Plugin = Plugin
