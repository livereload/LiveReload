
module.exports = class Registrator

  constructor: (@plugin, @schema) ->

  fileVar: (name, type, options={}) ->
    @schema.addFileVarDef name, type, options

  projectVar: (name, type, options={}) ->
    @schema.addProjectVarDef name, type, options

  fileAnalyzer: (fileGroup, func) ->
    @schema.addFileAnalyzer @plugin.resolveGroup(fileGroup), func

  projectAnalyzer: (func) ->
    @schema.addProjectAnalyzer func
