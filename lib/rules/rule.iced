R = require 'reactive'


class Rule extends R.Model

  constructor: (@action, info) ->
    @setInfo(info)

  memento: ->
    memento = @getInfo()
    memento.action = @action.id
    memento


class FileToFileRule extends Rule

  schema:
    action:                   { type: 'object' }
    sourceSpec:               { type: String }
    destSpec:                 { type: String }

  setInfo: (info) ->
    @sourceSpec = info.src
    @destSpec   = info.dst

  getInfo: ->
    { src: @sourceSpec, dst: @destSpec }


exports.Rule = Rule
exports.FileToFileRule = FileToFileRule
