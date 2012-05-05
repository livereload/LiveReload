R = require '../reactive'
{ makeObject } = require '../uilib/util'

class DurationWithCheckboxVM extends R.Entity

  constructor: (@durationProperty) ->
    super()

    @__defprop 'enabled', (@durationProperty.get() > 0.001),
      onchange: =>
        @durationProperty.set(0) if not @enabled

    @__deriveprop 'duration',
      compute: =>
        if @enabled
          '' + @durationProperty.get()
        else
          ''
      set: (newValue) =>
        newValue = parseFloat(newValue)
        @durationProperty.set(newValue)  unless isNaN(newValue)


class MonitoringOptionsVM extends R.Entity

  constructor: (@project) ->
    @delayFullRefresh = new DurationWithCheckboxVM(@project.fullPageReloadDelay$$)
    @eventProcessingDelay = new DurationWithCheckboxVM(@project.eventProcessingDelay$$)

    @__deriveprop 'builtInExtensions', =>
      LR.pluginManager.extensionsToMonitor.join(' ')

    @__deriveprop 'customExtensionsToMonitor',
      compute: =>
        LR.model.settings.customExtensionsToMonitor.join(' ')

      set: (newValue) =>
        extensions =
          if newValue = newValue.trim()
            newValue.split(/\s+/)
          else
            []
        LR.model.settings.customExtensionsToMonitor = extensions


module.exports = class MonitoringOptionsController

  constructor: (@project) ->
    @id = '#monitoring'
    @project.fullPageReloadDelay = 2.5
    @vm = new MonitoringOptionsVM(@project)

  initialize: ->
    @$
      'parent-window': '#mainwindow'
      'parent-style': 'sheet'
      visible: yes

  '#disableLiveRefreshCheckBox checkbox-binding': -> @project.disableLiveRefresh$$
  '#remoteServerWorkflowButton checkbox-binding': -> @project.enableRemoteServerWorkflow$$

  '#delayFullRefreshCheckBox checkbox-binding': -> @vm.delayFullRefresh.enabled$$
  '#fullRefreshDelayTextField text-binding':    -> @vm.delayFullRefresh.duration$$
  '#fullRefreshDelayTextField enabled-binding': -> @vm.delayFullRefresh.enabled$$

  '#delayChangeProcessingButton checkbox-binding':   -> @vm.eventProcessingDelay.enabled$$
  '#changeProcessingDelayTextField text-binding':    -> @vm.eventProcessingDelay.duration$$
  '#changeProcessingDelayTextField enabled-binding': -> @vm.eventProcessingDelay.enabled$$

  '#additionalExtensionsTextField text-binding': -> @vm.customExtensionsToMonitor$$

  '#applyButton clicked': ->
    @$ visible: no

  render: ->
    @$ '#builtInExtensionsLabelField': text: @vm.builtInExtensions
