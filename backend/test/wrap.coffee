Gently = require 'andreyvit-gently'
helper = require './helper'
process.setMaxListeners(1000)  # disable a warning about too many listener caused by Gently hooking process.exit

_testContext = null

beforeEach ->
  _testContext = {}
  _testContext.gently = gently = new Gently()
  _testContext.LR = helper.setup()
  for id in ['stub', 'hijack', 'expect', 'verify', 'restore']
    _testContext[id] = do (id) -> (args...) -> gently[id].apply(gently, args)

afterEach ->
  _testContext.verify()
  _testContext = null
  delete global.LR if global.LR

module.exports = wrap = (func) ->
  if func.length is 1
    return (done) ->
      func.call _testContext, done
  else
    return ->
      func.call(_testContext)
