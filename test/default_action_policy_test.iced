# { ok, equal, deepEqual } = require 'assert'
# DefaultActionPolicy = require '../lib/misc/rule_calc'

# describe "Rule Computation", ->

#   o = (files, existingRules, expectedRules) ->
#     policy = new DefaultActionPolicy([])
#     newRules = policy.compute(files, existingRules)
#     deepEqual newRules, expectedRules

#   it "should return no rules on an empty project", ->
#     o [], [], []

#   it "should cover a single file with an implicit rule", ->
#     o ['foo.less'], [], ['**/*.less -> **/*.css']
