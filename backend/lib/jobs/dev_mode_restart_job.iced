Job = require '../app/jobs'

module.exports = class DevModeRestartJob extends Job

  constructor: ->
    super null

  merge: (sibling) ->

  execute: (callback) ->
    setTimeout @executeForReal.bind(@), 200  # before we can self-host, give another instance of LiveReload a chance to finish compilation

  executeForReal: ->
    LR.log.fyi "LiveReload backend change detected. Restarting."
    process.exit 49  # a magic code signalling a backend restart (note: not 42 to avoid false positives)
