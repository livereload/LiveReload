R = require 'reactive'
_ = require 'underscore'

TypeToRuleClass =
  'compile-file': require('./rule').FileToFileRule


module.exports =
class RuleSet extends R.Model

  schema:
    project:                  { type: Object }
    rules:                    { type: Array }

  initialize: ({ @actions }) ->
    @rules = @createDefaultRules()

  setMemento: (memento) ->
    @rules =
      for info in memento
        @createRule(@_findAction(info.action), info)

  memento: ->
    (rule.memento() for rule in @rules)

  createRule: (action, info) ->
    # TODO: check that action is one of @actions
    ruleClass = @_getRuleClassForAction(action)
    return @universe.create(ruleClass, _.extend({}, { action, @project }, info))

  addRule: (action, info) ->
    @rules.push @createRule(action, info)

  createDefaultRules: ->
    rules = []
    for action in @actions
      if infos = action.createDefaultRules()
        for info in infos
          rule = @createRule(action, info)
          rules.push rule
    rules

  _getRuleClassForAction: (action) ->
    TypeToRuleClass[action.type] or throw new Error "Invalid 'type' of action #{action.constructor.name}: #{JSON.stringify(action.type)}"

  _findAction: (actionId) ->
    _.find(@actions, (a) => a.id is actionId) or throw new Error "Unknown action ID #{actionId}"
