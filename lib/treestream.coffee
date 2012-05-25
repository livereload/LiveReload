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


  visit: (path) ->
    @enter()

    fs.stat path, (err, stats) =>
      if err
        @emit 'error', err

      else
        if stats.isDirectory()
          unless @list?.membership(path, yes) is no
            @_traverse path
        else
          if !@list or @list.membership(path, no) is yes
            @emit 'file', path

      @leave()

    return this


  _traverse: (parent) ->
    @enter()
    @emit 'folder', parent

    fs.readdir parent, (err, names) =>
      if err
        @emit 'error', err

      else
        for name in names
          @visit Path.join(parent, name), parent

      @leave()
