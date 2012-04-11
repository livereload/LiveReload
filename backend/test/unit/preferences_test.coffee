# assert    = require 'assert'
# { setup } = require '../helper'

# describe "LR.preferences", ->
#   beforeEach (done) ->
#     setup ['preferences']
#     LR.preferences.setTestingOptions savingDelay: 1
#     LR.preferences.init process.env['TMPDIR'], done

#   it "should give back the stored values", (done) ->
#     LR.preferences.set 'foo.bar', 42, ->
#       LR.preferences.get 'foo.bar', (value) ->
#         assert.equal value, 42
#         setTimeout done, 10  # give it a chance to trigger saving and fail on saving errors
