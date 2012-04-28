
module.exports = class ApplicationController

  initialize: ->
    @$ '#mainwindow': {}

  '#mainwindow controller?': ->
    new (require './mainwindow')
