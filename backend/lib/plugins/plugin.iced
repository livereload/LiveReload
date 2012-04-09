fs   = require 'fs'
Path = require 'path'

{ Compiler } = require './tool'

class LRPlugin
  constructor: (@folder) ->
    @name = Path.basename(@folder, '.lrplugin')

  initialize: (callback) ->
    @compilers = {}

    @manifestFile = "#{@folder}/manifest.json"
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

    # console.log "Loaded manifest at #{@folder} with #{@manifest.LRCompilers.length} compilers"
    callback(null)


module.exports = LRPlugin
