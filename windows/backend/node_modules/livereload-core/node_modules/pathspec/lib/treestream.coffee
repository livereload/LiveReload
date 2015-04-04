Path = require 'path'
fs   = require 'fs'

{ EventEmitter } = require 'events'


StarList =
  membership: (path, isDir) -> yes


module.exports = class TreeStream extends EventEmitter

  constructor: (@list=StarList) ->
    @depth = 0


  enter: ->
    ++@depth

  leave: ->
    if --@depth is 0
      @emit 'end'


  visit: (root) ->
    @_visit(root, '')

  _visit: (root, path) ->
    @enter()

    absPath = Path.join(root, path)

    fs.stat absPath, (err, stats) =>
      if err
        @emit 'error', err

      else
        if stats.isDirectory()
          unless @list?.membership(path, yes) is no
            @_traverse root, path, absPath
        else
          if !@list or @list.membership(path, no) is yes
            @emit 'file', path, absPath

      @leave()

    return this


  _traverse: (root, parent, absParent) ->
    @enter()
    @emit 'folder', parent, absParent

    fs.readdir absParent, (err, names) =>
      if err
        @emit 'error', err

      else
        for name in names
          @_visit root, Path.join(parent, name)

      @leave()
