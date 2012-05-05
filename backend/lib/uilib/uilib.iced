Stylesheet = require './stylesheet'
{ makeObject, splitSelector, selectorToTree } = require './util'
R = require '../reactive'

Tree =
  mkdir: (tree, path) ->
    for item in path
      tree = (tree[item] ||= {})
    tree

  cd: (tree, path) ->
    for item in path
      tree = tree?[item]
    tree

  set: (tree, path, value) ->
    [prefix..., suffix] = path
    Tree.mkdir(tree, prefix)[suffix] = value

  get: (tree, path, value) ->
    [prefix..., suffix] = path
    Tree.cd(tree, prefix)[suffix]


class UIControllerWrapper

  constructor: (@parent, @prefix, @controller) ->
    @controller.$ = @update.bind(@)
    @controller.createChildWindow = @createChildWindow.bind(@)

    @selectorsToChildControllers        = {}
    @selectorsTestedForChildControllers = {}

    @enqueuedPayload    = {}
    @batchUpdateNestingLevel = 0

    @reversePrefix = @prefix.slice(0).reverse()
    @name = (@parent && "#{@parent.name}/" || "") + @controller.constructor.name + (@prefix.length > 0 && "(#{@prefix.join(' ')})" || "")

  initialize: ->
    @batchUpdates =>
      @rescan()
      @instantiateCoControllers()
      @controller.initialize()
      for own _, childControllers of @selectorsToChildControllers
        for childController in childControllers
          # LR.log.fyi "Initializing child controller #{childController.name}"
          childController.initialize()
          # LR.log.fyi "Done initializing child controller #{childController.name}"
      R.runNamed @name + "_render", =>
        @controller.render?()
      @hookElementsMentionedInSelectors()

  createChildWindow: (controller) ->
    if @parent
      @parent.createChildWindow(controller)
    else
      unless controller.id
        throw new Error("createChildWindow: controller must have an id")

      wrapper = @addChildController(controller.id, controller)
      wrapper.initialize()


  ################################################################################
  # outgoing payloads

  update: (payload) ->
    # LR.log.fyi "update of #{@name}: " + JSON.stringify(payload, null, 2)
    @batchUpdates =>
      @_sendUpdate payload

      # any update payloads sent while initializing child controllers have to be merged into this payload
      # because some properties provided by those updates might be only settable at UI creation time
      for own key, value of payload
        @instantiateChildControllers [key]

  _sendChildUpdate: (childWrapper, payload) ->
    # LR.log.fyi "_sendChildUpdate from #{childWrapper.name} to #{@name}: " + JSON.stringify(payload, null, 2)
    @_sendUpdate payload

  batchUpdates: (func) ->
    @batchUpdateNestingLevel++
    try
      func()
    finally
      @batchUpdateNestingLevel--

    @_submitEnqueuedPayload()

  _sendUpdate: (payload, func) ->
    # TODO: smarter merge (merge #smt and .smt keys, overwrite property keys even if they are objects like 'data')
    # (or maybe it's better to use update rather than overwrite semantics for the 'data' property)
    @enqueuedPayload = Object.merge @enqueuedPayload, payload, true
    # LR.log.fyi "#{@name}._sendUpdate merged payload: " + JSON.stringify(@enqueuedPayload, null, 2)

    @_submitEnqueuedPayload()

  _submitEnqueuedPayload: ->
    return unless @batchUpdateNestingLevel == 0

    # LR.log.fyi "#{@name}._submitEnqueuedPayload: " + JSON.stringify(@enqueuedPayload, null, 2)
    payload = @enqueuedPayload
    @enqueuedPayload = {}

    for key in @reversePrefix
      payload = makeObject(key, payload)
    @$ payload


  ################################################################################
  # child controllers

  instantiateCoControllers: ->
    # LR.log.fyi "#{@name}.instantiateCoControllers(): " + JSON.stringify(Object.keys(@eventToSelectorToHandler['controller?'] || {}))
    for own selector, handler of @eventToSelectorToHandler['controller?'] || {}
      if selector.match /^%[a-zA-Z0-9-]+$/
        @instantiateChildController '', handler, selector

  addChildController: (selector, childController) ->
    LR.log.fyi "Adding a child controller for #{selector} of #{@name}"
    wrapper = new UIControllerWrapper(this, splitSelector(selector), childController)
    (@selectorsToChildControllers[selector] ||= []).push wrapper
    wrapper.$ = @_sendChildUpdate.bind(@, wrapper)
    # LR.log.fyi "Done adding child controller #{wrapper.name}"
    return wrapper

  instantiateChildController: (selector, handler, handlerSpecSelector) ->
    # LR.log.fyi "Instantiating a child controller for #{handlerSpecSelector}, actual selector '#{selector}'"
    if childController = handler.call(@controller)
      @addChildController selector, childController

  instantiateChildControllers: (path) ->
    childSelector = path.join(' ')
    if @selectorsTestedForChildControllers[childSelector]
      return
    @selectorsTestedForChildControllers[childSelector] = yes

    handlers = @collectHandlers @handlerTree, path, 'controller?'
    for { handler, selector } in handlers
      @instantiateChildController childSelector, handler, selector


  ################################################################################
  # incoming payloads

  notify: (payload, path=[]) ->
    # if path.length == 0
    #   LR.log.fyi "Notification received: " + JSON.stringify(payload, null, 2)

    selector = path.join(' ')
    for childController in @selectorsToChildControllers[selector] || []
      # LR.log.fyi "Handing payload off to #{childController.name}"
      childController.notify(payload)

    for own key, value of payload
      if key[0] == '#'
        path.push key
        @notify value, path
        path.pop()
      else
        @invoke path, key, value,

  invoke: (path, event, arg) ->
    event = "#{event}!" unless event.match /[?!]$/

    # LR.log.fyi "Looking for handlers for path #{path.join(' ')}, event #{event}"
    Function::toJSON = -> "<func>"
    # LR.log.fyi "Handler tree: " + JSON.stringify(@handlerTree, null, 2)
    delete Function::toJSON

    handlers = @collectHandlers @handlerTree, path, event, '*' + event.match(/[?!]$/)[0]
    for { handler, selector } in handlers
      # LR.log.fyi "Invoking handler for #{selector}"
      handler.call(@controller, arg, path, event)


  ################################################################################
  # selector/handler hookup

  collectHandlers: (node, path, event, wildcardEvent=null, handlers=[], selectorComponents=[]) ->
    # LR.log.fyi "collectHandlers(node at '#{selectorComponents.join(' ')}', '#{path.join(' ')}', '#{event}', '#{wildcardEvent}', handlers #{handlers.length})"
    if path.length > 0
      if subnode = node[path[0]]
        selectorComponents.push(path[0])
        @collectHandlers(subnode, path.slice(1), event, wildcardEvent, handlers, selectorComponents)
        selectorComponents.pop()
      if subnode = node['*']
        selectorComponents.push('*')
        @collectHandlers(subnode, path.slice(1), event, wildcardEvent, handlers, selectorComponents)
        selectorComponents.pop()
    else
      if handler = node[event]
        selector = selectorComponents.concat([event]).join(' ')
        handlers.push { handler, selector }
      if wildcardEvent and (handler = node[wildcardEvent])
        selector = selectorComponents.concat([wildcardEvent]).join(' ')
        handlers.push { handler, selector }
    return handlers

  rescan: ->
    @handlerTree = {}
    @eventToSelectorToHandler = {}

    # intentionally traversing the prototype chain here
    for key, value of @controller when key.indexOf(' ') >= 0
      key = key.replace /\s+/g, ' '
      [elementSpec..., eventSpec] = splitSelector(key)

      for component in elementSpec
        unless component.match /^[#%.][a-zA-Z0-9-]+$/
          throw new Error("Invalid element spec '#{component}' in selector '#{key}' of #{@name}")
      unless eventSpec is '*' or eventSpec.match /^[a-zA-Z0-9-]+[?!]?$/
        throw new Error("Invalid event spec '#{eventSpec}' in selector '#{key}' of #{@name}")

      # because we sometimes put elements and events into the same tree, we need them to have different names;
      # e.g. "#foo *" would be overwritten by "#foo * clicked" if we didn't rename '*' event into '*!'.
      # note that allowing other suffixes like '?' (and exposing them to the user) was likely a stupid idea.
      eventSpec = "#{eventSpec}!" unless eventSpec.match /[?!]$/

      Tree.set @handlerTree, [elementSpec..., eventSpec], value
      Tree.set @eventToSelectorToHandler, [eventSpec, elementSpec.join(' ')], value

  hookElementsMentionedInSelectors: ->
    @__hookElementsMentionedInSelectors @handlerTree

  __hookElementsMentionedInSelectors: (node, path=[]) ->
    any = no
    for own key, value of node when key[0] == '#' and Object.isObject(value)
      path.push(key)
      @__hookElementsMentionedInSelectors value, path
      path.pop(key)
      any = yes
    unless any
      payload = {}
      for key in path.slice(0).reverse()
        payload = makeObject(key, payload)
      @update payload

module.exports = class UIDirector

  constructor: (rootController, styles) ->
    @rootControllerWrapper = new UIControllerWrapper(null, [], rootController)
    @rootControllerWrapper.$ = @update.bind(@)
    @stylesheet = new Stylesheet(styles)

  start: (callback) ->
    @rootControllerWrapper.initialize()
    callback(null)

  update: (payload) ->
    @stylesheet.annotate payload
    LR.log.fyi "Final outgoing payload with stylesheet applied: " + JSON.stringify(payload, null, 2)
    C.ui.update payload

  notify: (payload) ->
    LR.log.fyi "Incoming payload: " + JSON.stringify(payload, null, 2)
    @rootControllerWrapper.notify payload
