debug   = require('debug')('livereload:cli')
_       = require 'underscore'
R       = require('livereload-core').R
UIModel = require './base'
Path    = require 'path'


n = (number, strings...) ->
  variant = (if number is 1 then 0 else 1)
  string = strings[variant]
  return string.replace('#', number)


module.exports =
class MainWindow extends UIModel

  schema:
    status:                   { type: String, default: '' }
    stats:                    {}
    selectedProject:          {}
    selectedFile:             {}

  context: '#mainwnd'


  initialize: ({ @app, @session }) ->
    super(@app)


  ##################################################################################################
  # status

  'automatically render status': ->
    stats = @app.stats
    @SEND '#textBlockStatus': text: (@status or "Idle. #{n stats.connectionCount, '1 browser connected', '# browsers connected'}. #{n stats.changes, '1 change', '# changes'}, #{n stats.compilations, '1 file compiled', '# files compiled'}, #{n stats.refreshes, '1 refresh', '# refreshes'} so far.")


  ##################################################################################################
  # project list

  'automatically render project list': ->
    @SEND
      '#treeViewProjects':
        data:
          for project in @session.projects
            {
              id:     project.id
              text:   project.name
            }

  'on #treeViewProjects selectedId': (id) ->
    @selectedProject = @session.findProjectById(id)

  'automatically enable project list controls': ->
    @SEND
      '#buttonProjectAdd':
        enabled: yes
      '#buttonProjectRemove':
        enabled: !!@selectedProject

  'on #buttonProjectAdd click': ->
    await @SEND { '!chooseOutputFolder': [{ initial: null }] }, defer(err, result)
    if result.ok
      @status = "selected = #{result.path}"
      @session.addProject @app.vfs, result.path

  'on #buttonProjectRemove click': ->
    if @selectedProject
      @selectedProject.destroy()


  ##################################################################################################
  # project details - overview

  'automatically render project info': ->
    @SEND
      '#projectName':
        text: @selectedProject?.name or ''
      '#projectPath':
        text: if @selectedProject then Path.dirname(@selectedProject.path) else ''
      '#checkBoxCompile':
        value: !!@selectedProject?.compilationEnabled ? no
        enabled: yes
      '#tabs':
        visible: !!@selectedProject

  'automatically render snippet': ->
    @SEND '#textBoxSnippet': text: @selectedProject?.snippet or ''

  'automatically render url': ->
    @SEND '#textBoxUrl': text: @selectedProject?.urls?.join(", ") or ''

  'on #textBoxUrl text': (value) ->
    debug "WHEEE in 'on #textBoxUrl text', selectedProject = #{selectedProject?.id}, value = '#{value}'"
    @selectedProject.urls = value.split(/[\s,]+/).filter((u) -> u.length > 0)  if @selectedProject

  'on #checkBoxCompile value': (value) ->
    @selectedProject.compilationEnabled = value


  ##################################################################################################
  # project details - paths

  # 'automatically render path tree': ->
  #   @SEND
  #     '#buttonSetOutputFolder': {}
  #     '#treeViewPaths':
  #       data:
  #         for rule in @selectedProject?.ruleSet?.rules or []
  #           {
  #             id: "rule-#{rule._id}"
  #             text: "#{rule.action.name}:  #{rule.sourceSpec}   →   #{rule.destSpec}"
  #             children:
  #               for file in rule.files
  #                 if file.isImported
  #                   text = "#{file.relpath}  (imported)"
  #                 else
  #                   text = "#{file.relpath}   →   #{file.destRelPath}"
  #                 {
  #                   id: file.relpath
  #                   text: text
  #                   editable: true
  #                 }
  #           }

  # 'on #treeViewPaths selectedId': (relpath) ->
  #   if @selectedProject
  #     @selectedFile = @selectedProject.fileAt(relpath)
  #   else
  #     @selectedFile = null

  # 'on #treeViewPaths * text': (itemId, text) ->
  #   debug "in-place editing for itemId = '#{itemId}', text = '#{text}'"
  #   return unless @selectedProject
  #   relpath = itemId.substr(1)
  #   if file = @selectedProject.fileAt(relpath)
  #     debug "found file at #{relpath}"
  #     file.outputNameMask = text.replace(/^.*(→|>)/, '').trim() + "*"

  # 'on #buttonSetOutputFolder click': ->
  #   return unless @selectedFile

  #   initial = @selectedFile.fullDestDir

  #   await @SEND { '!chooseOutputFolder': [{ initial: initial }] }, defer(err, result)
  #   if result.ok
  #     @selectedFile.fullDestDir = result.path
  #     @status = "@selectedFile relpath = #{JSON.stringify(@selectedFile.relpath)}, destDir = #{JSON.stringify(@selectedFile.destDir)}"
  #     # saveProjects()
