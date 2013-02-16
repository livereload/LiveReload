debug   = require('debug')('livereload:cli')
_       = require 'underscore'
R       = require('livereload-core').R
UIModel = require './base'

MainWindow = require './mainwnd'
Stats      = require './stats'


module.exports =
class ApplicationUI extends UIModel

  schema:
    mainwnd: {}

  initialize: ({ @vfs, @session }) ->
    super()
    @stats = @universe.create(Stats)
    @mainwnd = @universe.create(MainWindow, app: this, session: @session)
