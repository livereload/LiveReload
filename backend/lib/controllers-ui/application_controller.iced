

module.exports = class ApplicationController

  initialize: ->
    @$ '#mainwindow': {}

  '#mainwindow controller?': ->
    new (require './main_window_controller')
