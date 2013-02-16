{ ok, equal, deepEqual } = require 'assert'

{ Action, CompilationAction, RuleSet, R } = require "../#{process.env.JSLIB or 'lib'}/session"


class MockAction extends Action

  type: 'compile-file'

  constructor: (tag='A') ->
    super("mock-#{tag}", "Mock #{tag}")


describe "RuleSet", ->

  it "should be creatable", ->
    universe = new R.Universe()
    ruleSet = universe.create(RuleSet, actions: [new MockAction()])
    deepEqual ruleSet.rules, []

  it "should export a memento", ->
    universe = new R.Universe()
    action = new MockAction()
    ruleSet = universe.create(RuleSet, actions: [action])
    ruleSet.addRule action, { src: '*.less', dst: '*.css' }
    deepEqual ruleSet.memento(), [{ action: "mock-A", src: "*.less", dst: "*.css" }]

  it "should import a memento", ->
    universe = new R.Universe()
    action = new MockAction()
    ruleSet = universe.create(RuleSet, actions: [action])
    ruleSet.setMemento [{ action: "mock-A", src: "*.less", dst: "*.css" }]
    equal ruleSet.rules.length, 1
    equal ruleSet.rules[0].sourceSpec, '*.less'
    equal ruleSet.rules[0].destSpec,   '*.css'

  it "should set up initial rules", ->
    universe = new R.Universe()
    compiler = { id: 'more', name: 'More', extensions: ['more'], destinationExt: 'css' }
    action = new CompilationAction(compiler)
    ruleSet = universe.create(RuleSet, actions: [action])
    equal ruleSet.rules.length, 1
    equal ruleSet.rules[0].sourceSpec, '**/*.more'
    equal ruleSet.rules[0].destSpec,   '**/*.css'
