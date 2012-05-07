
module.exports = class Registrator

  constructor: (@plugin) ->

  fileVar: (name, type, options={}) ->
    LR.log.fyi "Plugin #{@plugin.name} adds file var #{name}"

  projectVar: (name, type, options={}) ->

  fileAnalyzer: (fileGroup, func) ->

  projectAnalyzer: (func) ->
