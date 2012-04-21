Gently = require 'andreyvit-gently'
helper = require './helper'
process.setMaxListeners(1000)  # disable a warning about too many listener caused by Gently hooking process.exit

_testContext = null

_nesting = 0

beforeEach ->
  # ++_nesting
  # console.error "\nbeforeEach #{_nesting}"
  # if _nesting > 1
  #   return

    # console.error "Nesting error: #{_nesting} in beforeEach"
    # throw new Error("Nesting error: #{_nesting} in beforeEach")

  _testContext ||= {}
  _testContext.gently = gently = new Gently()
  for id in ['stub', 'hijack', 'expect', 'verify', 'restore']
    _testContext[id] = do (id) -> (args...) -> gently[id].apply(gently, args)

afterEach ->
  # if _nesting > 0
  #   --_nesting
  #   console.error "\nafterEach #{_nesting}"
  # else
  #   console.error "\nafterEach 0 !!"
  # if _nesting isnt 1
  #   return

  if _testContext?
    _testContext.verify()
    # _testContext = null
  return

module.exports = wrap = (func) ->
  if func.length is 1
    return (done) ->
      if _testContext is null
        throw new Error("_testContext is null!")
      func.call _testContext, done
  else
    return ->
      func.call(_testContext)
