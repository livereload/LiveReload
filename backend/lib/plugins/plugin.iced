fs   = require 'fs'
Path = require 'path'

require '../util/moresugar'

{ Compiler } = require './tool'

Registrator = require './registrator'

class LRPlugin
  constructor: (@folder) ->
    @name = Path.basename(@folder, '.lrplugin')

  initialize: (callback) ->
    @compilers = {}

    @manifestFile = "#{@folder}/manifest.json"
    @codeFile = "#{@folder}/index.js"
    await @parseManifest defer()
    @loadCode()
    callback(null)

  parseManifest: (callback) ->
    try
      @processManifest JSON.parse(fs.readFileSync(@manifestFile, 'utf8')), callback
    catch e
      callback(e)

  loadCode: ->
    return unless Path.existsSync(@codeFile)
    func = require(@codeFile)
    func(new Registrator(this))

  processManifest: (@manifest, callback) ->
    for compilerManifest in @manifest.LRCompilers || []
      compiler = new Compiler(this, compilerManifest)
      @compilers[compiler.id] = compiler

    @extensionsToMonitor = @manifest.extensionsToMonitor || []
    @fileAndFolderNamesToIgnore = @manifest.fileAndFolderNamesToIgnore || []

    # console.log "Loaded manifest at #{@folder} with #{@manifest.LRCompilers.length} compilers"
    callback(null)


module.exports = LRPlugin
