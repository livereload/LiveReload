
module.exports = class Registrator

  constructor: (@plugin, @schema) ->

  fileVar: (name, type, options={}) ->
    @schema.addFileVarDef name, type, options

  projectVar: (name, type, options={}) ->
    @schema.addProjectVarDef name, type, options

  fileAnalyzer: (name, fileGroup, func) ->
    @schema.addFileAnalyzer @uid(name), @plugin.resolveGroup(fileGroup), func

  projectAnalyzer: (name, func) ->
    @schema.addProjectAnalyzer @uid(name), func

  uid: (name) ->
    (@plugin.name + " " + name).replace(/[^a-zA-Z0-9]+/g, '_')
