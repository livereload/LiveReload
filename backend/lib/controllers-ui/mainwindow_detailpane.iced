
module.exports = class DetailPaneController

  constructor: (@model) ->

  initialize: ->

  '#compilerEnabledCheckBox clicked': (arg) ->
    @model.selectedProject.compilationEnabled = !!arg

  '#postProcessingEnabledCheckBox clicked': (arg) ->
    @model.selectedProject.postprocEnabled = !!arg

  render: ->
    project = @model.selectedProject
    return unless project

    @$
      '#nameTextField': text: project?.name ? ''

      '#pathTextField': text: project?.path ? '(select a project)'

      '#monitoringSummaryLabelField': text: "Monitoring 123 file extensions."

      '#compilerEnabledCheckBox': state: @model.selectedProject.compilationEnabled

      '#postProcessingEnabledCheckBox': state: @model.selectedProject.postprocEnabled
