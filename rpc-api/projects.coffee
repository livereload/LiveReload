_session = null
_vfs = null

sendUpdate = ->
  LR.rpc.send 'update', {
    projects:
      for project in _session.projects
        { id: project.id, name: project.name, path: project.path }
  }


exports.init = (vfs, session) ->
  _vfs = vfs
  _session = session
  sendUpdate()

exports.api =
  add: ({ path }, callback) ->
    _session.addProject _vfs, path
    sendUpdate()
    callback()

  remove: ({ id }, callback) ->
    callback()

  changeDetected: ({ id, changes }, callback) ->
