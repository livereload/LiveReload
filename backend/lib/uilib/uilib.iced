{ EventEmitter } = require 'events'


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

makeObject = (key, value) ->
  object = {}
  object[key] = value
  return object


class UIControllerWrapper extends EventEmitter

  constructor: (@prefix, @controller) ->
    @controller.$ = @update.bind(@)
    @reversePrefix = @prefix.slice(0).reverse()

  initialize: ->
    @controller.initialize()
    @rescan()

  rescan: ->
    @handlerTree = {}

    # intentionally traversing the prototype chain here
    for key, value of @controller when key.indexOf(' ') >= 0
      [elementSpec..., eventSpec] = key.split(' ')

      for component in elementSpec
        unless component.match /^#[a-zA-Z0-9-]+$/
          throw new Error("Invalid element spec '#{component}' in selector '#{key}'")
      unless eventSpec is '*' or eventSpec.match /^[a-zA-Z0-9-]+[?!]?$/
        throw new Error("Invalid event spec '#{eventSpec}' in selector '#{key}'")

      eventSpec = "#{eventSpec}!" unless eventSpec.match /[?!]$/

      Tree.set @handlerTree, [elementSpec..., eventSpec], value

  update: (data) ->
    for key in @reversePrefix
      data = makeObject(key, data)
    @emit 'update', data

  notify: (payload, path=[]) ->
    if path.length == 0
      LR.log.fyi "Notification received: " + JSON.stringify(payload, null, 2)
    for own key, value of payload
      if key[0] == '#'
        path.push key
        @notify value, path
        path.pop()
      else
        @invoke path, key, value,

  invoke: (path, event, arg) ->
    event = "#{event}!" unless event.match /[?!]$/

    LR.log.fyi "Looking for handlers for path #{path.join(' ')}, event #{event}"
    Function::toJSON = -> "<func>"
    LR.log.fyi "Handler tree: " + JSON.stringify(@handlerTree, null, 2)
    delete Function::toJSON

    handlers = @collectHandlers @handlerTree, path, event, '*' + event.match(/[?!]$/)[0]
    for { handler, selector } in handlers
      LR.log.fyi "Invoking handler for #{selector}"
      handler.call(@controller, arg, path, event)

  collectHandlers: (node, path, event, wildcardEvent, handlers=[], selectorComponents=[]) ->
    LR.log.fyi "collectHandlers(node at '#{selectorComponents.join(' ')}', '#{path.join(' ')}', '#{event}', '#{wildcardEvent}', handlers #{handlers.length})"
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
      if handler = node[wildcardEvent]
        selector = selectorComponents.concat([wildcardEvent]).join(' ')
        handlers.push { handler, selector }
    return handlers


module.exports = class UIDirector

  constructor: (rootController) ->
    @rootControllerWrapper = new UIControllerWrapper([], rootController)
    @rootControllerWrapper.on 'update', @update.bind(@)

  start: (callback) ->
    @rootControllerWrapper.initialize()
    callback(null)

  update: (payload) ->
    C.ui.update payload

  notify: (payload) ->
    @rootControllerWrapper.notify payload
