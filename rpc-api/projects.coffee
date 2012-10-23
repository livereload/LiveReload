debug = require('debug')('livereload:cli')
Path  = require 'path'
fs    = require 'fs'
_     = require 'underscore'

_session = null
_vfs = null
_dataFile = null

_stats = {
  connectionCount: 0
  changes:       0
  compilations:  0
  refreshes:     0
}
_status = ""

n = (number, strings...) ->
  variant = (if number is 1 then 0 else 1)
  string = strings[variant]
  return string.replace('#', number)


sendStatus = ->
  message = _status or "Idle. #{n _stats.connectionCount, '1 browser connected', '# browsers connected'}. #{n _stats.changes, '1 change', '# changes'}, #{n _stats.compilations, '1 file compiled', '# files compiled'}, #{n _stats.refreshes, '1 refresh', '# refreshes'} so far."
  LR.rpc.send 'status', { status: message }

sendStatus = _.throttle(sendStatus, 50)


sendUpdate = ->
  LR.rpc.send 'update', {
    projects:
      for project in _session.projects
        {
          id:       project.id
          name:     project.name
          path:     project.path
          url:      project.urls.join(", ")
          snippet:  project.snippet
          compilationEnabled: !!project.compilationEnabled
        }
  }
  sendStatus()


saveProjects = ->
  memento = {
    projects:
      for project in _session.projects
        {
          path: project.path
          compilationEnabled: !!project.compilationEnabled
          urls: project.urls
        }
  }
  fs.writeFileSync(_dataFile, JSON.stringify(memento, null, 2))
  sendUpdate()


setStatus = (status) ->
  _status = status
  sendStatus()


exports.init = (vfs, session, appDataDir) ->
  _vfs = vfs
  _session = session
  _dataFile = Path.join(appDataDir, 'projects.json')

  session.on 'run.start', (project, run) =>
    _stats.changes += run.change.paths.length

  session.on 'run.finish', (project, run) =>
    LR.client.projects.notifyChanged({})
    setStatus ''


  statusClearingTimeout = null

  session.on 'action.start', (project, action) =>
    switch action.id
      when 'compile'
        _stats.compilations += 1
      when 'refresh'
        _stats.refreshes += 1

    clearTimeout(statusClearingTimeout) if statusClearingTimeout?
    setStatus action.message + "..."

  session.on 'action.finish', (project, action) =>
    clearTimeout(statusClearingTimeout) if statusClearingTimeout?
    statusClearingTimeout = setTimeout((-> setStatus ''), 50)


  if fs.existsSync(_dataFile)
    try
      data = JSON.parse(fs.readFileSync(_dataFile, 'utf8'))
    catch e
      data = null
    if data
      projects = {}
      for project in data.projects or [] when project.path
        projects[project.path] = project
      _session.setProjectsMemento _vfs, projects

  saveProjects()


exports.api =
  add: ({ path }, callback) ->
    _session.addProject _vfs, path
    saveProjects()
    callback()

  remove: ({ id }, callback) ->
    if project = _session.findProjectById(id)
      project.destroy()
    saveProjects()
    callback()

  update: ({ id, compilationEnabled, url }, callback) ->
    if project = _session.findProjectById(id)
      if compilationEnabled?
        project.compilationEnabled = !!compilationEnabled
      if url?
        project.urls = url.split(/[\s,]+/).filter((u) -> u.length > 0)
    saveProjects()
    callback()

  changeDetected: ({ id, changes }, callback) ->


exports.setConnectionStatus = ({ connectionCount }) ->
  _stats.connectionCount = connectionCount
  sendStatus()
