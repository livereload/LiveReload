{ EventEmitter } = require 'events'

class UIObject extends EventEmitter
  constructor: (@options) ->
    @handle = null
    @_init()

  _init: ->

  _createBindings: -> {}

class UIControl extends UIObject

  _init: ->
    if @options.click
      @on 'click', @options.click
      delete @options.click

  _createBindings: ->
    click: =>
      @emit 'click'

class UIButton extends UIControl

class UIWindow extends UIObject
  constructor: (@className, controls={}) ->
    @controls = []
    @add controls

  add: (name, control) ->
    if Object.isObject name
      for own k, v of name
        @add k, v
      return

    control.name = name
    @controls.push control
    this[name] = control

  create: (callback) ->
    bindings = {}
    objects = {}
    bindings.window = @_createBindings()
    objects.window = this
    for control in @controls
      bindings[control.name] = control._createBindings()
      objects[control.name] = control

    await C.ui.createWindow {
      @className
      bindings
    }, defer(err, response)

    for own k, _ of bindings
      objects[k].handle = response[k]

    callback(null)

  show: (callback) ->
    C.ui.showWindow { window: @handle }, callback

module.exports = {
  UIObject
  UIControl
  UIButton
  UIWindow
}
