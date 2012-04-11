Gently = require 'andreyvit-gently'
helper = require './helper'
process.setMaxListeners(1000)  # disable a warning about too many listener caused by Gently hooking process.exit

_testContext = null

beforeEach ->
  _testContext = {}
  _testContext.gently = gently = new Gently()
  for id in ['stub', 'hijack', 'expect', 'verify', 'restore']
    _testContext[id] = do (id) -> (args...) -> gently[id].apply(gently, args)

afterEach ->
  if _testContext?
    _testContext.verify()
    _testContext = null
  return

module.exports = wrap = (func) ->
  if func.length is 1
    return (done) ->
      func.call _testContext, done
  else
    return ->
      func.call(_testContext)
