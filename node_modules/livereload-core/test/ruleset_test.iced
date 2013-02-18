{ ok, equal, deepEqual } = require 'assert'

{ Action, CompilationAction, RuleSet } = require "../#{process.env.JSLIB or 'lib'}/session"


class MockAction extends Action

  type: 'compile-file'

  constructor: (tag='A') ->
    super("mock-#{tag}", "Mock #{tag}")


describe "RuleSet", ->

  it "should be creatable", ->
    ruleSet = new RuleSet([new MockAction()])
    deepEqual ruleSet.rules, []

  it "should export a memento", ->
    action = new MockAction()
    ruleSet = new RuleSet([action])
    ruleSet.addRule action, { src: '*.less', dst: '*.css' }
    deepEqual ruleSet.memento(), [{ action: "mock-A", src: "*.less", dst: "*.css" }]

  it "should import a memento", ->
    action = new MockAction()
    ruleSet = new RuleSet([action])
    ruleSet.setMemento [{ action: "mock-A", src: "*.less", dst: "*.css" }]
    equal ruleSet.rules.length, 1
    equal ruleSet.rules[0].sourceSpec, '*.less'
    equal ruleSet.rules[0].destSpec,   '*.css'

  it "should set up initial rules", ->
    compiler = { id: 'more', name: 'More', extensions: ['more'], destinationExt: 'css' }
    action = new CompilationAction(compiler)
    ruleSet = new RuleSet([action])
    equal ruleSet.rules.length, 1
    equal ruleSet.rules[0].sourceSpec, '**/*.more'
    equal ruleSet.rules[0].destSpec,   '**/*.css'
