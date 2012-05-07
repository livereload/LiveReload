fs   = require 'fs'
Path = require 'path'

require '../util/moresugar'

{ Compiler } = require './tool'
FSGroup = require '../vfs/fsgroup'

Registrator = require './registrator'

class LRPlugin
  constructor: (@folder) ->
    @name = Path.basename(@folder, '.lrplugin')

  initialize: (analysisSchema, callback) ->
    @compilers = {}

    @manifestFile = "#{@folder}/manifest.json"
    @codeFile = "#{@folder}/index.js"
    await @parseManifest defer()
    @loadCode(analysisSchema) unless analysisSchema.skipInUnitTest
    callback(null)

  parseManifest: (callback) ->
    try
      @processManifest JSON.parse(fs.readFileSync(@manifestFile, 'utf8')), callback
    catch e
      callback(e)

  loadCode: (analysisSchema) ->
    return unless Path.existsSync(@codeFile)
    func = require(@codeFile)
    func(new Registrator(this, analysisSchema))

  processManifest: (@manifest, callback) ->
    for compilerManifest in @manifest.LRCompilers || []
      compiler = new Compiler(this, compilerManifest)
      @compilers[compiler.id] = compiler

    @extensionsToMonitor = @manifest.extensionsToMonitor || []
    @fileAndFolderNamesToIgnore = @manifest.fileAndFolderNamesToIgnore || []
    @nameToFileGroup = @manifest.fileGroups || {}

    # console.log "Loaded manifest at #{@folder} with #{@manifest.LRCompilers.length} compilers"
    callback(null)

  resolveGroup: (fileGroup) ->
    if typeof fileGroup is 'string'
      if @nameToFileGroup[fileGroup]
        fileGroup = @nameToFileGroup[fileGroup]
      return FSGroup.parse(fileGroup)
    else
      fileGroup

module.exports = LRPlugin
