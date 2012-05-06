R = require '../reactive'

module.exports = class PostprocOptionsController extends R.Entity

  constructor: (@project) ->
    @id = '#postproc'
    @wasEmpty = (!@project.postprocCommand)

  initialize: ->
    @$ visible: yes

  '#command text-binding': ->
    get: =>
      @project.postprocCommand
    set: (newValue) =>
      @project.postprocCommand = newValue.trim()

  '#apply clicked': ->
    if @project.postprocCommand and @wasEmpty
      @project.postprocEnabled = yes
    else if !@project.postprocCommand
      @project.postprocEnabled = no

    @$ visible: no
