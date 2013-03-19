debug = require('debug')('livereload:cli')
Path  = require 'path'
fs    = require 'fs'
_     = require 'underscore'
R = require('livereload-core').R

ApplicationUI = require '../lib/ui/app'
UIConnector = require '../lib/uilib'


_session = null
_vfs = null
_dataFile = null
_root = null


saveProjects = ->
  _session.makeProjectsMemento (err, projects) ->
    throw err if err
    memento = { projects }
    fs.writeFileSync(_dataFile, JSON.stringify(memento, null, 2))


UPDATE = (payload, callback) ->
  LR.rpc.send 'rpc', payload, callback


exports.init = (vfs, session, appDataDir) ->
  _vfs = vfs
  _session = session
  _dataFile = Path.join(appDataDir, 'projects.json')

  _root = session.universe.create(ApplicationUI, vfs: _vfs, session: _session)
  _connector = new UIConnector(_root)
  _connector.on 'update', (payload, callback) -> UPDATE(payload, callback)

  session.on 'run.start', (project, run) =>
    _root.stats.changes += run.change.paths.length

  session.on 'run.finish', (project, run) =>
    LR.client.projects.notifyChanged({})
    _root.mainwnd.status = ''
    saveProjects()


  statusClearingTimeout = null

  session.on 'action.start', (project, action) =>
    switch action.id
      when 'compile'
        _root.stats.compilations += 1
      when 'refresh'
        _root.stats.refreshes += 1

    clearTimeout(statusClearingTimeout) if statusClearingTimeout?
    _root.mainwnd.status = action.message + "..."

  session.on 'action.finish', (project, action) =>
    clearTimeout(statusClearingTimeout) if statusClearingTimeout?
    statusClearingTimeout = setTimeout((-> _root.mainwnd.status = ''), 50)


  if fs.existsSync(_dataFile)
    try
      data = JSON.parse(fs.readFileSync(_dataFile, 'utf8'))
    catch e
      data = null
    if data
      _session.setProjectsMemento _vfs, (data.projects or [])

  LR.rpc.send 'update', {
    projects: []
  }

  _session.pleasedo "Save the projects", ->
    saveProjects()


exports.api =
  add: ({ path }, callback) ->
    callback()

  remove: ({ id }, callback) ->
    callback()

  changeDetected: ({ id, changes }, callback) ->

  rpc: (payload, callback) ->
    _root.receive(payload)
    callback()


exports.setConnectionStatus = ({ connectionCount }) ->
  _root.stats.connectionCount = connectionCount
