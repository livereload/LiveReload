
{ Workspace } = require '../lib/model/workspace'

_workspace = new Workspace()

exports.findById = (projectId) -> _workspace.findById(projectId)

exports.init = (callback) -> _workspace.init(callback)

exports.updateProjectList = (callback) -> _workspace.updateProjectList(callback)

exports.api =
  add: (arg, callback) -> _workspace.add arg, callback
  remove: (arg, callback) -> _workspace.remove arg, callback
  changeDetected: (arg, callback) -> _workspace.changeDetected arg, callback
