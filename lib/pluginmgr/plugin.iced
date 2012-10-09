debug = require('debug')('livereload:core:plugins')
fs    = require 'fs'
Path  = require 'path'
util  = require 'util'
_     = require 'underscore'

CommandLineTool = require '../tools/cmdline'
MessageParser   = require '../messages/parser'


class Compiler
  constructor: (@plugin, @manifest) ->
    @name = @manifest.Name
    @extensions = @manifest.Extensions or []
    @sourceSpecs = ("*.#{ext}" for ext in @extensions)

    @tool = new CommandLineTool
      name:   @name
      args:   @manifest.CommandLine
      cwd:    (@manifest.RunIn or "$(project_dir)")
      parser: new MessageParser(errors: @manifest.Errors or [], warnings: @manifest.Warnings or [])

    @importRegExps =
      for re in @manifest.ImportRegExps or []
        new RegExp(re)


exports.Compiler = Compiler


class Plugin
  constructor: (@folder) ->

  initialize: (callback) ->
    @compilers = {}

    @manifestFile = "#{@folder}/manifest.json"
    @parseManifest(callback)

  parseManifest: (callback) ->
    try
      @processManifest JSON.parse(fs.readFileSync(@manifestFile, 'utf8')), callback
    catch e
      debug "Error parsing manifest #{@manifestFile}: #{e.stack}"
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

  constructor: ->
    @folders = []

  addFolder: (folder) ->
    @folders.push folder

  rescan: (callback) ->
    pluginFolders = []
    for folder in @folders
      debug "Scanning plugin folder: #{JSON.stringify(folder)}"
      for entry in fs.readdirSync(folder) when entry.match(/\.lrplugin$/)
        pluginFolders.push Path.join(folder, entry)

    errs = {}
    result = []
    await
      for folder, i in pluginFolders
        loadPlugin folder, defer(errs[folder], result[i])

    for own folder, err of errs when err
      err.message = "Error loading plugin from #{folder}: #{err.message}"
      return callback(err)

    @plugins = result

    @compilers = {}
    for plugin in @plugins
      _.extend @compilers, plugin.compilers

    @allCompilers = (compiler for own name, compiler of @compilers)

    return callback(null)


exports.PluginManager = PluginManager
exports.Plugin = Plugin
