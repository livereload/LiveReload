R = require '../reactive'

module.exports = class CompilationOptionsController extends R.Entity

  constructor: (@project) ->
    @id = '#compilation'
    @selectedFilePath = null

  initialize: ->
    @$ visible: yes

  # '#command text-binding': ->
  #   get: =>
  #     @project.postprocCommand
  #   set: (newValue) =>
  #     @project.postprocCommand = newValue.trim()

  '#apply clicked': ->
    @$ visible: no



  #############################################################################
  # outputPaths

  'automatically render outputPaths': ->
    @$ '#outputPaths': rows:
      for path in Object.keys(@project.fileOptionsByPath).sort()
        options = @project.fileOptionsByPath[path]

        {
          id: path
          on: !!options.enabled
          source: path
          output: (options.outputDir || '.') + "/" + options.outputNameMask
        }

  '#outputPaths selectedRow': (rowId) ->
    @selectedFilePath = rowId

  '#setOutputFolder clicked': ->
    @$ '$do': 'chooseFolderToExclude':
      callback: (path) =>
        if path
          @project.excludedPaths = @project.excludedPaths.concat([path])

  '#setOutputFile clicked': ->
    @$ '$do': 'chooseFolderToExclude':
      callback: (path) =>
        if path
          @project.excludedPaths = @project.excludedPaths.concat([path])

  '#applyMask clicked': ->
