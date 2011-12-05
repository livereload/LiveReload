fs = require 'fs'
path = require 'path'
yaml = require 'js-yaml'
util = require 'util'
plist = require 'plist'
async = require 'async'
require 'sugar'


class Compiler
  constructor: (@plugin, @manifest) ->
    @name = @manifest.Name
    @parser = new MessageParser(@manifest)


class Plugin
  constructor: (@folder) ->

  initialize: (callback) ->
    @compilers = {}

    plist.parseFile "#{@folder}/Info.plist", (err, obj) =>
      @manifest = obj[0]
      console.log "Loaded manifest at #{@folder} with #{@manifest.LRCompilers.length} compilers"

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


class LiveReload
  initialize: (data, callback) ->
    @pluginManager = new PluginManager(data.pluginFolders)
    @pluginManager.rescan (err) ->
      callback(err)

LR = new LiveReload()

Commands =
  'init': (data) ->
    console.log "init!"
    LR.initialize data, (err) ->
      if err
        console.log "init failed: #{err}"
      else
        console.log "init ok"

Comm =
  send: (args...) ->
    payload = JSON.stringify(args)
    process.stdout.write "#{payload}\n"

process.stdin.resume()
process.stdin.setEncoding('utf8')

process.stdin.on 'data', (chunk) ->
  process.stderr.write('Node received command: ' + chunk);
  [command, args...] = JSON.parse(chunk)
  console.log "command = '#{command}'"
  Commands[command].apply(null, args)

process.stdin.on 'end', ->
  process.exit(0)
