debug = require('debug')('livereload:cli')
Path  = require 'path'
fs    = require 'fs'

_session = null
_vfs = null
_dataFile = null

sendUpdate = ->
  LR.rpc.send 'update', {
    projects:
      for project in _session.projects
        { id: project.id, name: project.name, path: project.path, compilationEnabled: !!project.compilationEnabled }
  }

saveProjects = ->
  memento = {
    projects:
      for project in _session.projects
        {
          path: project.path
          compilationEnabled: !!project.compilationEnabled
        }
  }
  fs.writeFileSync(_dataFile, JSON.stringify(memento, null, 2))
  sendUpdate()


exports.init = (vfs, session, appDataDir) ->
  _vfs = vfs
  _session = session
  _dataFile = Path.join(appDataDir, 'projects.json')

  session.on 'run.finish', =>
    LR.client.projects.notifyChanged({})

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
    saveProjects()
    callback()

  update: ({ id, compilationEnabled }, callback) ->
    if project = _session.findProjectById(id)
      if compilationEnabled?
        project.compilationEnabled = !!compilationEnabled
    saveProjects()
    callback()

  changeDetected: ({ id, changes }, callback) ->
